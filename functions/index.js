const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 🔁 Supprime les tokens FCM invalides de la base de données.
 */
async function cleanInvalidTokens(tokensToClean) {
  if (tokensToClean.length === 0) return;

  const usersToUpdate = await admin.firestore().collection("users")
    .where("fcmToken", "in", tokensToClean)
    .get();

  const batch = admin.firestore().batch();
  usersToUpdate.forEach(doc => {
    batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
  });

  await batch.commit();
  logger.info(`🧹 ${tokensToClean.length} token(s) invalides supprimés.`);
}

/**
 * 📊 Gère la réponse d'envoi de FCM, log les erreurs et nettoie les tokens invalides.
 */
async function handleFcmResponse(response, tokens) {
  logger.info("✅ Résultat de l'envoi FCM :", {
    successCount: response.successCount,
    failureCount: response.failureCount,
  });

  const invalidTokens = [];
  response.responses.forEach((res, i) => {
    if (!res.success) {
      const errorCode = res.error?.code;
      logger.warn(`❌ Token #${i} échoué : ${errorCode}`);
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(tokens[i]);
      }
    }
  });

  await cleanInvalidTokens(invalidTokens);
}

// 🔔 1. Envoi lors de la création d'une nouvelle panne
exports.sendNotificationOnNewPanne = onDocumentCreated(
  { region: "europe-west3", document: "pannes/{panneId}" },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Aucune donnée reçue.");
      return;
    }

    const { type, ville, quartier } = snapshot.data();
    logger.info(`🚨 Nouvelle panne à ${quartier}, ${ville} (type: ${type})`);

    const usersSnapshot = await admin.firestore().collection("users")
      .where("ville", "==", ville)
      .where("quartier", "==", quartier)
      .get();

    let tokens = usersSnapshot.docs.map(doc => doc.data().fcmToken).filter(Boolean);
    tokens = [...new Set(tokens)];

    if (tokens.length === 0) {
      logger.info("📭 Aucun utilisateur trouvé pour cette panne.");
      return null;
    }

    const message = {
      notification: {
        title: "🚨 Alerte Allo Coupure 🚨",
        body: `Une coupure d'${type} a été signalée à ${quartier}, ${ville}.`,
      },
      android: { priority: "high" },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        ...message,
      });
      return await handleFcmResponse(response, tokens);
    } catch (error) {
      logger.error("💥 Erreur d'envoi (panne) :", error);
      return null;
    }
  }
);

// ✅ 2. Envoi quand le service est restauré
exports.sendNotificationOnServiceRestored = onDocumentUpdated(
  { region: "europe-west3", document: "pannes/{panneId}" },
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    const beforeRestaurations = beforeData.restaurations ?? [];
    const afterRestaurations = afterData.restaurations ?? [];

    // ⚠️ Envoi uniquement si au moins 2 personnes ont confirmé le retour
    if (
      afterRestaurations.length > beforeRestaurations.length &&
      afterRestaurations.length >= 2
    ) {
      const { type, ville, quartier } = afterData;
      logger.info(`✅ Service restauré à ${quartier}, ${ville} (type: ${type})`);

      const usersSnapshot = await admin.firestore().collection("users")
        .where("ville", "==", ville)
        .where("quartier", "==", quartier)
        .get();

      let tokens = usersSnapshot.docs.map(doc => doc.data().fcmToken).filter(Boolean);
      tokens = [...new Set(tokens)];

      if (tokens.length === 0) {
        logger.info("📭 Aucun utilisateur trouvé (retour de service).");
        return null;
      }

      const message = {
        notification: {
          title: "✅ Info Service Allo Coupure ✅",
          body: `Le service d'${type} semble rétabli dans votre quartier : ${quartier}.`,
        },
        android: { priority: "high" },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          ...message,
        });
        return await handleFcmResponse(response, tokens);
      } catch (error) {
        logger.error("💥 Erreur d'envoi (retour service) :", error);
        return null;
      }
    }

    return null;
  }
);
