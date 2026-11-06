require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const propertyRoutes = require('./routes/propertyRoutes');
const surveyRoutes = require('./routes/surveyRoutes');
const purchaseRoutes = require('./routes/purchaseRoutes');
const consultationRoutes = require('./routes/consultationRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminPropertyRoutes = require('./routes/adminPropertyRoutes');
const adminUserRoutes = require('./routes/adminUserRoutes');
const reportRoutes = require('./routes/reportRoutes');
const invoiceRoutes = require('./routes/invoiceRoutes');
const errorHandler = require('./middleware/errorHandler');
const { getAllowedCorsOrigins } = require('./config/security');

const app = express();
const allowedOrigins = getAllowedCorsOrigins();
const allowAllOrigins = allowedOrigins.includes('*');
const localHosts = new Set(['localhost', '127.0.0.1']);

function isLocalLoopbackOrigin(origin) {
  try {
    const parsed = new URL(origin);
    return ['http:', 'https:'].includes(parsed.protocol) && localHosts.has(parsed.hostname);
  } catch (_) {
    return false;
  }
}

function isAllowedOrigin(origin) {
  if (allowAllOrigins) {
    return true;
  }

  if (allowedOrigins.includes(origin)) {
    return true;
  }

  if (isLocalLoopbackOrigin(origin)) {
    return true;
  }

  try {
    const parsed = new URL(origin);
    const alternateHost = parsed.hostname === 'localhost' ? '127.0.0.1' : parsed.hostname === '127.0.0.1' ? 'localhost' : null;

    if (!alternateHost) {
      return false;
    }

    parsed.hostname = alternateHost;
    return allowedOrigins.includes(parsed.toString().replace(/\/$/, ''));
  } catch (_) {
    return false;
  }
}

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (isAllowedOrigin(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin tidak diizinkan oleh konfigurasi CORS'));
    },
  }),
);
app.use(express.json());
app.use(
  '/uploads/profile-photos',
  express.static(path.join(__dirname, '..', 'uploads', 'profile-photos'), {
    index: false,
    redirect: false,
    setHeaders(res) {
      res.setHeader('X-Content-Type-Options', 'nosniff');
    },
  }),
);
app.use(
  '/uploads/properties',
  express.static(path.join(__dirname, '..', 'uploads', 'properties'), {
    index: false,
    redirect: false,
    setHeaders(res) {
      res.setHeader('X-Content-Type-Options', 'nosniff');
    },
  }),
);
app.use(
  '/uploads/payment-proofs',
  express.static(path.join(__dirname, '..', 'uploads', 'payment-proofs'), {
    index: false,
    redirect: false,
    setHeaders(res) {
      res.setHeader('X-Content-Type-Options', 'nosniff');
    },
  }),
);
app.use(
  '/uploads/consultations',
  express.static(path.join(__dirname, '..', 'uploads', 'consultations'), {
    index: false,
    redirect: false,
    setHeaders(res) {
      res.setHeader('X-Content-Type-Options', 'nosniff');
    },
  }),
);

app.get('/api/health', (req, res) => {
  res.json({ message: 'Backend berjalan' });
});

app.use('/api/auth', authRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/surveys', surveyRoutes);
app.use('/api/purchases', purchaseRoutes);
app.use('/api/consultations', consultationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin/properties', adminPropertyRoutes);
app.use('/api/admin/users', adminUserRoutes);
app.use('/api/admin/reports', reportRoutes);
app.use('/api/admin/invoices', invoiceRoutes);

const todoRoutes = require('./routes/todoRoutes');
app.use('/api/todos', todoRoutes);

const buyerRecordRoutes = require('./routes/buyerRecordRoutes');
app.use('/api/admin/buyer-records', buyerRecordRoutes);


app.use(errorHandler);

// ─── Serve Flutter Web build ───────────────────────────────────────────────
const webBuildPath = path.join(__dirname, '..', '..', 'build', 'web');
const fs = require('fs');
if (fs.existsSync(webBuildPath)) {
  app.use(express.static(webBuildPath));
  // SPA fallback — semua route non-API diarahkan ke index.html
  app.get('*', (req, res) => {
    if (!req.path.startsWith('/api') && !req.path.startsWith('/uploads')) {
      res.sendFile(path.join(webBuildPath, 'index.html'));
    }
  });
}

module.exports = app;
