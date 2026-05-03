const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");

const app = express();

/* ---------------- MIDDLEWARE ---------------- */
app.use(cors());
app.use(express.json({ limit: "2mb" }));

/* ---------------- FIREBASE ADMIN ---------------- */
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

/* ---------------- AUTH MIDDLEWARE ---------------- */
async function verifyToken(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.split("Bearer ")[1];

    if (!token) {
      return res.status(401).json({ error: "Missing token" });
    }

    req.user = await admin.auth().verifyIdToken(token);
    next();
  } catch (err) {
    res.status(401).json({ error: "Invalid token" });
  }
}

/* ---------------- EMAIL TRANSPORT ---------------- */
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

/* ---------------- SEND EMAIL ---------------- */
app.post("/send", verifyToken, async (req, res) => {
  try {
    const { to, subject, body } = req.body;

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to,
      subject,
      text: body,
      html: body
    });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ---------------- MOCK EMAIL LIST (REPLACE LATER WITH IMAP) ---------------- */
app.get("/emails", verifyToken, async (req, res) => {
  res.json({
    messages: [
      {
        from: "Firebase <no-reply@firebase.com>",
        subject: "Welcome to Mmail",
        html: "<h2>It works 🎉</h2><p>Your system is live.</p>",
        date: Date.now()
      }
    ]
  });
});

/* ---------------- START SERVER ---------------- */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("Mmail backend running on", PORT);
});
