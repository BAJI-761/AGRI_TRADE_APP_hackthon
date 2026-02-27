const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Trade Lifecycle Manager
 * Listens for changes to 'lifecycleAction' in 'orders' collection.
 * Transitions 'tradeState' deterministically.
 */
exports.onOrderUpdate = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();
        const orderId = context.params.orderId;

        // 1. Detect lifecycleAction change
        const action = newData.lifecycleAction;
        const previousAction = previousData.lifecycleAction;

        // If no action or action hasn't changed, ignore
        if (!action || action === previousAction) {
            return null;
        }

        console.log(`[Order ${orderId}] Lifecycle action detected: ${action}`);
        console.log(`[Order ${orderId}] Current TradeState: ${newData.tradeState}`);

        const db = admin.firestore();
        const orderRef = db.collection("orders").doc(orderId);

        try {
            await db.runTransaction(async (t) => {
                const doc = await t.get(orderRef);
                if (!doc.exists) {
                    throw new Error("Order does not exist");
                }

                const data = doc.data();
                const currentTradeState = data.tradeState || "pending";
                // Check legacy status if tradeState is pending/null just in case, but prefer tradeState
                const effectiveState = (currentTradeState === "pending" && data.status === "accepted")
                    ? "accepted"
                    : currentTradeState;

                let newTradeState = effectiveState;
                let updates = {};

                console.log(`[Order ${orderId}] Processing ${action} on state ${effectiveState}`);

                // 2. Validate & Transition
                switch (action) {
                    case "holdPayment":
                        // Valid from 'accepted'
                        if (effectiveState === "accepted") {
                            newTradeState = "paymentHeld";
                        } else {
                            console.warn(`[Order ${orderId}] Invalid transition: holdPayment called on ${effectiveState}`);
                        }
                        break;

                    case "confirmDelivery":
                        // Valid from 'paymentHeld'
                        if (effectiveState === "paymentHeld") {
                            newTradeState = "completed";
                            updates.reputationImpact = 1; // Phase 5 requirement
                        } else {
                            console.warn(`[Order ${orderId}] Invalid transition: confirmDelivery called on ${effectiveState}`);
                        }
                        break;

                    case "raiseDispute":
                        // Valid from 'paymentHeld'
                        if (effectiveState === "paymentHeld") {
                            newTradeState = "disputed";
                            updates.reputationImpact = -1; // Phase 5 requirement

                            // disputeReason is assumed to be written directly to the doc by the client 
                            // when setting lifecycleAction, or passed in lifecycleAction payload if it was an object.
                            // Current implementation: client writes disputeReason to doc separately or with action.
                        } else {
                            console.warn(`[Order ${orderId}] Invalid transition: raiseDispute called on ${effectiveState}`);
                        }
                        break;

                    default:
                        console.warn(`[Order ${orderId}] Unknown action: ${action}`);
                        break;
                }

                // 3. Apply Updates if state changed
                if (newTradeState !== effectiveState) {
                    updates.tradeState = newTradeState;
                    console.log(`[Order ${orderId}] Transitioning: ${effectiveState} -> ${newTradeState}`);
                } else {
                    console.log(`[Order ${orderId}] No state transition occurred.`);
                }

                // 4. Always consume the action (delete it) to prevent loops/re-trigger
                // We use FieldValue.delete() to remove the field
                updates.lifecycleAction = admin.firestore.FieldValue.delete();

                t.update(orderRef, updates);
            });

            console.log(`[Order ${orderId}] Lifecycle update committed.`);
        } catch (e) {
            console.error(`[Order ${orderId}] Transaction failed:`, e);
        }
    });
