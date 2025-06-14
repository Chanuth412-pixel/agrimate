import express from 'express';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();
const app = express();
app.use(express.json());

app.post('/send-otp', async (req, res) => {
  const { phone, message } = req.body;

  try {
    const response = await axios.post('https://api.mspace.lk/otp/send', {
      phone,
      message
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.MSPACE_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    res.json(response.data);
  } catch (err) {
    console.error(err?.response?.data || err.message);
    res.status(500).json({ error: 'OTP sending failed' });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Running on ${PORT}`));
