const axios = require("axios");

const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY;

async function initializeChapaPayment({
  amount,
  email,
  firstName,
  lastName,
  txRef,
  callbackUrl,
  returnUrl,
}) {
  if (!CHAPA_SECRET_KEY) {
    throw new Error("CHAPA_SECRET_KEY is missing.");
  }

  const response = await axios.post(
    "https://api.chapa.co/v1/transaction/initialize",
    {
      amount: amount.toString(),
      currency: "ETB",
      email,
      first_name: firstName,
      last_name: lastName,
      tx_ref: txRef,
      callback_url: callbackUrl,
      return_url: returnUrl,
    },
    {
      headers: {
        Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

module.exports = {
  initializeChapaPayment,
};