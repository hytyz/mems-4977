import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from "@firebase/rules-unit-testing";
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs, Timestamp,
} from "firebase/firestore";

const env = await initializeTestEnvironment({
  projectId: "demo-mems",
  firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8"), host: "127.0.0.1", port: 8080 },
});

const alice = env.authenticatedContext("alice", { userEmail: "alice@example.com" }).firestore();
const bob = env.authenticatedContext("bob", { userEmail: "bob@example.com" }).firestore();
const noClaim = env.authenticatedContext("carol", {}).firestore();
const anon = env.unauthenticatedContext().firestore();

let failures = 0;
async function t(label, promise) {
  try { await promise; console.log("PASS", label); }
  catch (e) { failures++; console.log("FAIL", label, e.message); }
}

const now = Timestamp.now();
const sel = (uid, email, candidateId, extra = {}) => ({
  id: `${uid}_${candidateId}`, userEmail: email, candidateId, candidateName: "Jordan Lee",
  candidatePhotoUrl: "/uploads/candidates/jordan-lee.png", positionId: 1, positionName: "Mayor",
  municipalityId: 1, municipalityName: "Pitt Meadows", notes: "", dateCreated: now, dateModified: now,
  ...extra,
});
const S = (db, id) => doc(db, "CandidateSelections", id);

await t("owner can read missing own doc (duplicate check)", assertSucceeds(getDoc(S(alice, "alice_1"))));
await t("cannot read missing doc of another uid", assertFails(getDoc(S(alice, "bob_1"))));
await t("owner creates selection", assertSucceeds(setDoc(S(alice, "alice_1"), sel("alice", "alice@example.com", 1))));
await t("photo url may be null", assertSucceeds(setDoc(S(alice, "alice_2"), sel("alice", "alice@example.com", 2, { candidatePhotoUrl: null }))));
await t("cannot create under another uid", assertFails(setDoc(S(alice, "bob_3"), sel("bob", "alice@example.com", 3))));
await t("cannot create with another email", assertFails(setDoc(S(alice, "alice_4"), sel("alice", "bob@example.com", 4))));
await t("id must match candidateId", assertFails(setDoc(S(alice, "alice_5"), sel("alice", "alice@example.com", 6))));
await t("notes > 500 rejected", assertFails(setDoc(S(alice, "alice_7"), sel("alice", "alice@example.com", 7, { notes: "x".repeat(501) }))));
await t("notes = 500 accepted", assertSucceeds(setDoc(S(alice, "alice_8"), sel("alice", "alice@example.com", 8, { notes: "x".repeat(500) }))));
await t("missing required field rejected", assertFails(setDoc(S(alice, "alice_9"), (() => { const d = sel("alice", "alice@example.com", 9); delete d.positionName; return d; })())));
await t("extra field rejected", assertFails(setDoc(S(alice, "alice_10"), sel("alice", "alice@example.com", 10, { admin: true }))));
await t("overwriting existing (duplicate) rejected", assertFails(setDoc(S(alice, "alice_1"), sel("alice", "alice@example.com", 1, { notes: "dup", dateCreated: Timestamp.fromMillis(0) }))));
await t("no userEmail claim rejected", assertFails(setDoc(S(noClaim, "carol_1"), sel("carol", "", 1))));
await t("unauthenticated rejected", assertFails(getDoc(S(anon, "alice_1"))));

await t("owner reads own doc", assertSucceeds(getDoc(S(alice, "alice_1"))));
await t("other user cannot read", assertFails(getDoc(S(bob, "alice_1"))));
await t("owner query by email + city", assertSucceeds(getDocs(query(collection(alice, "CandidateSelections"), where("userEmail", "==", "alice@example.com"), where("municipalityId", "==", 1)))));
await t("owner duplicate check by email + candidate", assertSucceeds(getDocs(query(collection(alice, "CandidateSelections"), where("userEmail", "==", "alice@example.com"), where("candidateId", "==", 1)))));
await t("duplicate check for other's email rejected", assertFails(getDocs(query(collection(bob, "CandidateSelections"), where("userEmail", "==", "alice@example.com"), where("candidateId", "==", 1)))));
await t("query for other's email rejected", assertFails(getDocs(query(collection(bob, "CandidateSelections"), where("userEmail", "==", "alice@example.com")))));
await t("unfiltered query rejected", assertFails(getDocs(collection(bob, "CandidateSelections"))));

await t("owner updates notes", assertSucceeds(updateDoc(S(alice, "alice_1"), { notes: "new", dateModified: Timestamp.now() })));
await t("owner cannot change candidate", assertFails(updateDoc(S(alice, "alice_1"), { candidateId: 99 })));
await t("owner cannot move to another city", assertFails(updateDoc(S(alice, "alice_1"), { municipalityId: 3 })));
await t("update notes > 500 rejected", assertFails(updateDoc(S(alice, "alice_1"), { notes: "y".repeat(501) })));
await t("other user cannot update", assertFails(updateDoc(S(bob, "alice_1"), { notes: "hacked" })));

await t("other user cannot delete", assertFails(deleteDoc(S(bob, "alice_1"))));
await t("owner deletes", assertSucceeds(deleteDoc(S(alice, "alice_1"))));

const P = (db, id) => doc(db, "UserProfiles", id);
const profile = (email, extra = {}) => ({ userEmail: email, municipalityId: 3, municipalityName: "Burnaby", dateModified: now, ...extra });
await t("owner saves profile", assertSucceeds(setDoc(P(alice, "alice"), profile("alice@example.com"))));
await t("owner changes municipality", assertSucceeds(setDoc(P(alice, "alice"), profile("alice@example.com", { municipalityId: 1, municipalityName: "Pitt Meadows" }))));
await t("owner reads profile", assertSucceeds(getDoc(P(alice, "alice"))));
await t("other cannot read profile", assertFails(getDoc(P(bob, "alice"))));
await t("other cannot write profile", assertFails(setDoc(P(bob, "alice"), profile("bob@example.com"))));
await t("profile with wrong email rejected", assertFails(setDoc(P(alice, "alice"), profile("bob@example.com"))));
await t("other collections closed", assertFails(getDoc(doc(alice, "Other/x"))));

await env.cleanup();
console.log(failures === 0 ? "ALL RULE TESTS PASSED" : `${failures} FAILED`);
process.exit(failures === 0 ? 0 : 1);
