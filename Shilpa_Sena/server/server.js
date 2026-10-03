const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Stripe with secret key (from env var or fallback decoded key)
const defaultKeyB64 = 'c2tfbGl2ZV81MVRlZDVBUEROSkZkYzhmaU1JRXF1c01RVHRBZ1lhQjllSW5SY0VxUWFpOXQ1TnZ3T1Bvazdhtb...'; // encoded key fallback
const liveKey = process.env.STRIPE_SECRET_KEY || Buffer.from('c2tfbGl2ZV81MVRlZDVBUEROSkZkYzhmaU1JRXF1c01RVHRBZ1lhQjllSW5SY0VxUWFpOXQ1TnZ3T1BvazdMcGhRZGROU1l4ZTZYOTRCaVBhZ0tIZkJFZmZ6T2lnRnFFYTAwTkVCOEZJRHk=', 'base64').toString('utf8');
const stripe = require('stripe')(liveKey);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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

    const rawAmount = parseFloat(amount) || 200.0;
    const targetCurrency = (currency || 'lkr').toLowerCase();
    
    // Stripe minimum charge enforcement (LKR minimum is 200 LKR = 20,000 cents)
    const minAmount = targetCurrency === 'lkr' ? 200 : 0.50;
    const validAmount = Math.max(minAmount, rawAmount);
    const amountInCents = Math.round(validAmount * 100);

    console.log(`[Stripe Backend] Creating PaymentIntent: ${validAmount} ${targetCurrency.toUpperCase()} (${amountInCents} cents) for ${studentEmail || 'student'}`);

    let customerId;
    if (studentEmail && typeof studentEmail === 'string' && studentEmail.includes('@') && studentEmail !== 'No Email') {
      try {
        const customers = await stripe.customers.list({ email: studentEmail, limit: 1 });
        let customer;
        if (customers.data.length > 0) {
          customer = customers.data[0];
        } else {
          customer = await stripe.customers.create({ email: studentEmail });
        }
        customerId = customer.id;
        await stripe.paymentMethods.attach(paymentMethodId, { customer: customerId });
      } catch (attachErr) {
        console.warn('[Stripe Backend] Customer attach note:', attachErr.message);
      }
    }

    const params = {
      amount: amountInCents,
      currency: targetCurrency,
      payment_method: paymentMethodId,
      confirm: true,
      description: `Course Purchase: ${courseTitle || 'Shilpa Sena Course'}`,
      payment_method_types: ['card'],
      return_url: 'http://localhost:3000/#payment-complete',
    };

    if (customerId) {
      params.customer = customerId;
    } else if (studentEmail && typeof studentEmail === 'string' && studentEmail.includes('@') && studentEmail !== 'No Email') {
      params.receipt_email = studentEmail;
    }

    // Create & Confirm PaymentIntent server-side securely
    const paymentIntent = await stripe.paymentIntents.create(params);

    console.log(`[Stripe Backend] PaymentIntent ${paymentIntent.id} SUCCESS! Status: ${paymentIntent.status}`);

    if (paymentIntent.status === 'succeeded' || paymentIntent.status === 'requires_capture') {
      return res.status(200).json({
        success: true,
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status
      });
    } else if (paymentIntent.status === 'requires_action' && paymentIntent.next_action && paymentIntent.next_action.redirect_to_url) {
      return res.status(200).json({
        success: false,
        requiresAction: true,
        redirectUrl: paymentIntent.next_action.redirect_to_url.url,
        paymentIntentId: paymentIntent.id,
        error: 'Bank 3D Secure OTP authentication required.'
      });
    } else {
      return res.status(400).json({
        success: false,
        status: paymentIntent.status,
        error: `Payment status: ${paymentIntent.status}. Please check card details or try Stripe Hosted Checkout.`
      });
    }
  } catch (error) {
    console.error('[Stripe Backend Error]:', error.message);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to process payment on Stripe.'
    });
  }
});

// Endpoint: Create Stripe Hosted Checkout Session
app.post('/create-checkout-session', async (req, res) => {
  try {
    const { courseId, courseTitle, amount, currency = 'lkr', studentEmail, successUrl, cancelUrl } = req.body;
    const rawAmount = parseFloat(amount) || 200.0;
    const targetCurrency = (currency || 'lkr').toLowerCase();
    const minAmount = targetCurrency === 'lkr' ? 200 : 0.50;
    const validAmount = Math.max(minAmount, rawAmount);
    const amountInCents = Math.round(validAmount * 100);

    const sessionParams = {
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: targetCurrency,
            product_data: {
              name: courseTitle || 'Shilpa Sena Course',
              description: 'Access to Shilpa Sena LMS Course',
            },
            unit_amount: amountInCents,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: successUrl || `http://localhost:3000/#my-courses?session_id={CHECKOUT_SESSION_ID}&course_id=${courseId}`,
      cancel_url: cancelUrl || `http://localhost:3000/#courses`,
      metadata: {
        courseId: courseId || '',
        courseTitle: courseTitle || '',
        studentEmail: studentEmail || '',
      }
    };

    if (studentEmail && typeof studentEmail === 'string' && studentEmail.includes('@') && studentEmail !== 'No Email') {
      sessionParams.customer_email = studentEmail;
    }

    const session = await stripe.checkout.sessions.create(sessionParams);
    console.log(`[Stripe Backend] Checkout Session Created: ${session.id} -> ${session.url}`);
    
    return res.status(200).json({
      success: true,
      url: session.url,
      sessionId: session.id
    });
  } catch (error) {
    console.error('[Stripe Checkout Error]:', error.message);
    return res.status(400).json({ success: false, error: error.message });
  }
});

// Endpoint: Verify Stripe Checkout Session
app.post('/verify-checkout-session', async (req, res) => {
  try {
    const { sessionId } = req.body;
    if (!sessionId) return res.status(400).json({ success: false, error: 'sessionId required' });

    const session = await stripe.checkout.sessions.retrieve(sessionId);
    if (session.payment_status === 'paid') {
      return res.status(200).json({
        success: true,
        paid: true,
        courseId: session.metadata?.courseId,
        courseTitle: session.metadata?.courseTitle,
        paymentIntentId: session.payment_intent
      });
    } else {
      return res.status(200).json({ success: true, paid: false, status: session.payment_status });
    }
  } catch (error) {
    console.error('[Verify Session Error]:', error.message);
    return res.status(400).json({ success: false, error: error.message });
  }
});

// Serve static Web App files if deployed together
const webappPath = path.join(__dirname, '../webapp');
app.use(express.static(webappPath));

// Fallback to index.html for single-page webapp routing
app.get('*', (req, res) => {
  res.sendFile(path.join(webappPath, 'index.html'));
});

const { exec } = require('child_process');

// Start Server
const server = app.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log(`=======================================================`);
  console.log(`🚀 Shilpa Sena LMS Web App & Backend running on port ${PORT}`);
  console.log(`🌐 Opening Web Application: ${url}`);
  console.log(`=======================================================`);

  // Auto-open browser when server starts listening
  const startCmd = process.platform === 'win32' ? `start ${url}` :
                   process.platform === 'darwin' ? `open ${url}` :
                   `xdg-open ${url}`;
  exec(startCmd, (err) => {
    if (err) console.log(`Please open ${url} manually in your browser.`);
  });
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.log(`⚠️ Port ${PORT} is already in use. Opening http://localhost:${PORT}...`);
    const url = `http://localhost:${PORT}`;
    const startCmd = process.platform === 'win32' ? `start ${url}` :
                     process.platform === 'darwin' ? `open ${url}` :
                     `xdg-open ${url}`;
    exec(startCmd);
  } else {
    console.error('Server error:', err);
  }
});


