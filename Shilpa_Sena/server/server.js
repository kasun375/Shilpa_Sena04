const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Stripe with secret key from environment variable
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || '';
const stripe = require('stripe')(stripeSecretKey);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static Web App files if deployed together
const webappPath = path.join(__dirname, '../webapp');
app.use(express.static(webappPath));

// Health Check Route
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'Shilpa Sena Stripe Payment Server',
    time: new Date().toISOString()
  });
});

app.get('/api/status', (req, res) => {
  res.json({
    status: 'online',
    service: 'Shilpa Sena Stripe Backend',
    liveMode: true
  });
});

// Endpoint: Create and Confirm Stripe PaymentIntent
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { paymentMethodId, amount, currency = 'lkr', courseTitle, studentEmail } = req.body;

    if (!paymentMethodId) {
      return res.status(400).json({ success: false, error: 'paymentMethodId is required' });
    }

    const rawAmount = parseFloat(amount) || 10.0;
    // Calculate amount in cents (minimum 50.00 LKR = 5000 cents in Stripe API)
    const targetCurrency = (currency || 'lkr').toLowerCase();
    const minAmount = targetCurrency === 'lkr' ? 50 : 0.50;
    const amountInCents = Math.max(Math.round(minAmount * 100), Math.round(rawAmount * 100));

    console.log(`[Stripe Backend] Processing charge of ${amountInCents} cents (${targetCurrency.toUpperCase()}) for ${studentEmail || 'student'}`);

    // Create & Confirm PaymentIntent server-side securely
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: currency.toLowerCase(),
      payment_method: paymentMethodId,
      confirm: true,
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never'
      },
      description: `Course Purchase: ${courseTitle || 'Shilpa Sena Course'}`,
      receipt_email: studentEmail || undefined
    });

    console.log(`[Stripe Backend] PaymentIntent ${paymentIntent.id} status: ${paymentIntent.status}`);

    if (paymentIntent.status === 'succeeded' || paymentIntent.status === 'requires_capture') {
      return res.status(200).json({
        success: true,
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status
      });
    } else {
      return res.status(400).json({
        success: false,
        status: paymentIntent.status,
        error: `Payment status is ${paymentIntent.status}. Further authentication may be required.`
      });
    }
  } catch (error) {
    console.error('[Stripe Backend Error]:', error.message);
    return res.status(500).json({
      success: false,
      error: error.message || 'Failed to process payment on Stripe backend server.'
    });
  }
});

// Fallback to index.html for single-page webapp routing
app.get('*', (req, res) => {
  res.sendFile(path.join(webappPath, 'index.html'));
});

// Start Server
app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 Shilpa Sena Stripe Payment Server running on port ${PORT}`);
  console.log(`=======================================================`);
});
