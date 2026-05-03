#!/data/data/com.termux/files/usr/bin/bash

echo "📦 Setting up Mmail..."

# init project if needed
[ ! -f package.json ] && npm init -y

# install deps
npm install express imap-simple mailparser nodemailer cors dotenv firebase-admin

# create .env if missing
if [ ! -f .env ]; then
cat > .env <<EOF
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
PORT=3000
EOF
fi

# create server.js if missing
if [ ! -f server.js ]; then
cat > server.js <<'EOF'
require("dotenv").config();

const express = require("express");
const imaps = require("imap-simple");
const nodemailer = require("nodemailer");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());
app.use(express.static("."));

const EMAIL = process.env.EMAIL_USER;
const PASS = process.env.EMAIL_PASS;

// IMAP config
const imapConfig = {
  imap: {
    user: EMAIL,
    password: PASS,
    host: "imap.gmail.com",
    port: 993,
    tls: true
  }
};

// inbox
app.get("/emails", async (req, res) => {
  try {
    const conn = await imaps.connect(imapConfig);
    await conn.openBox("INBOX");

    const messages = await conn.search(["ALL"], {
      bodies: [""],
      markSeen: false
    });

    const emails = messages.slice(-10).map(m => {
      const raw = m.parts.find(p => p.which === "").body;
      return {
        subject: raw.match(/Subject: (.*)/)?.[1] || "(no subject)",
        from: raw.match(/From: (.*)/)?.[1] || "unknown"
      };
    });

    conn.end();
    res.json(emails);
  } catch (e) {
    res.json({ error: e.message });
  }
});

// send email
app.post("/send", async (req, res) => {
  const { to, subject, body } = req.body;

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user: EMAIL, pass: PASS }
  });

  try {
    await transporter.sendMail({
      from: EMAIL,
      to,
      subject,
      text: body
    });

    res.json({ status: "sent" });
  } catch (e) {
    res.json({ error: e.message });
  }
});

app.listen(process.env.PORT || 3000, () =>
  console.log("🔥 Mmail running on http://localhost:3000")
);
EOF
fi

# create index.html if missing
if [ ! -f index.html ]; then
cat > index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Mmail</title>
</head>
<body>

<h2>Mmail 📬</h2>

<button onclick="loadInbox()">Inbox</button>
<button onclick="compose()">Compose</button>

<button onclick="login()">Sign in with Google</button>

<div id="inbox"></div>

<div id="composeBox" style="display:none;">
  <input id="to" placeholder="To"><br>
  <input id="subject" placeholder="Subject"><br>
  <textarea id="body"></textarea><br>
  <button onclick="send()">Send</button>
</div>

<script type="module">
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js";
import {
  getAuth,
  signInWithPopup,
  GoogleAuthProvider
} from "https://www.gstatic.com/firebasejs/10.7.0/firebase-auth.js";

const firebaseConfig = {
  apiKey: "YOUR_KEY",
  authDomain: "YOUR_DOMAIN",
  projectId: "YOUR_ID"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

window.login = async function () {
  const provider = new GoogleAuthProvider();
  const result = await signInWithPopup(auth, provider);

  const token = await result.user.getIdToken();
  localStorage.setItem("mmail_token", token);

  alert("Logged in as " + result.user.email);
};

window.loadInbox = async function () {
  const res = await fetch("/emails");
  const data = await res.json();

  document.getElementById("inbox").innerHTML =
    data.map(m => `<div><b>${m.subject}</b><br>${m.from}</div>`).join("");
};

window.compose = function () {
  document.getElementById("composeBox").style.display = "block";
};

window.send = async function () {
  await fetch("/send", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      to: to.value,
      subject: subject.value,
      body: body.value
    })
  });

  alert("Sent");
};
</script>

</body>
</html>
EOF
fi

echo "✅ Build complete"
echo "👉 Next: ./run.sh"
