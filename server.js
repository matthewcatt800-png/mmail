const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");

const app = express();

app.use(cors());
app.use(express.json());

/* ---------------- MEMORY INBOX (replace later with DB) ---------------- */
let emails = [];

/* ---------------- HEALTH CHECK ---------------- */
app.get("/", (req, res) => {
  res.json({ status: "Mmail backend running" });
});

/* ---------------- GET EMAILS (latest first) ---------------- */
app.get("/emails", (req, res) => {
  const sorted = [...emails].sort((a, b) => b.timestamp - a.timestamp);
  res.json(sorted);
});

/* ---------------- SEND EMAIL ---------------- */
app.post("/send", async (req, res) => {
  const { to, subject, body } = req.body;

  if (!to || !subject || !body) {
    return res.status(400).json({ error: "Missing fields" });
  }

  try {
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to,
      subject,
      text: body,
      html: body
    });

    emails.push({
      id: Date.now(),
      from: process.env.EMAIL_USER,
      to,
      subject,
      html: body,
      timestamp: Date.now()
    });

    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: "send failed" });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log("Mmail backend running on", PORT);
});
