// src/routes/auth.routes.js

const express = require('express');
const router = express.Router();
const User = require('../models/user.model');
const bcrypt = require('bcryptjs'); 
const jwt = require('jsonwebtoken'); 
const { protect } = require('../middleware/auth.middleware'); // <-- Middleware import'u

// SECRET anahtarı
const JWT_SECRET = 'cok_gizli_anahtar'; 

// Fonksiyon: Token oluşturma
const generateToken = (userId) => {
    return jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '1h' });
};

// @route   POST /api/auth/register
// @desc    Kullanıcı kaydı ve token döndürme
// @access  Public
router.post('/register', async (req, res) => {
    const { name, email, password } = req.body;
    try {
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ success: false, message: 'Bu e-posta zaten kullanımda.' });
        }

        user = new User({ name, email, password });
        // user.model.js'deki pre('save') hook'u şifreyi otomatik hash'leyecek
        await user.save(); 

        const token = generateToken(user._id);
        const userDetails = await User.findById(user._id).select('-password'); 

        res.status(201).json({ 
            success: true, 
            message: 'Kayıt başarılı!',
            token, 
            user: userDetails // Kullanıcı detayları (dersler dahil) döndürülür
        });

    } catch (err) {
        console.error("Kayıt Hatası:", err.message); // Hata takibi için log eklendi
        // Eğer Mongoose doğrulama hatası varsa (örneğin minlength)
        res.status(500).json({ success: false, message: 'Sunucu hatası veya eksik/yanlış veri girişi.' });
    }
});


// @route   POST /api/auth/login
// @desc    Kullanıcı girişi yapma ve token döndürme
// @access  Public
router.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        let user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ success: false, message: 'Geçersiz kimlik bilgileri.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ success: false, message: 'Geçersiz kimlik bilgileri.' });
        }

        const token = generateToken(user._id);
        const userDetails = await User.findById(user._id).select('-password'); 

        res.json({
            success: true,
            token,
            user: userDetails 
        });

    } catch (err) {
        console.error("Giriş Hatası:", err.message); // Hata takibi için log eklendi
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

// @route   GET /api/auth/profile
// @desc    Giriş yapmış kullanıcının profil verilerini döndür (Home ekranı için)
// @access  Private
router.get('/profile', protect, async (req, res) => {
    try {
        const user = await User.findById(req.userId)
            .select('-password')
            .populate('favorites', 'name email rating courses')
            .populate('incomingRequests', 'name email rating courses')
            .populate('pendingRequests', 'name email rating courses');
        if (!user) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }
        res.json({ success: true, user: user });
    } catch (err) {
        console.error("Profil Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

// @route   PUT /api/auth/update-courses
// @desc    Kullanıcının seçtiği dersleri kaydetme
// @access  Private (Yetkilendirme gerektirir)
router.put('/update-courses', protect, async (req, res) => {
    const { courses } = req.body; 

    if (!Array.isArray(courses)) {
        return res.status(400).json({ success: false, message: 'Ders listesi (courses) bir dizi olmalıdır.' });
    }

    try {
        const user = await User.findByIdAndUpdate(
            req.userId, // Middleware'den gelen ID
            { courses: courses }, 
            { new: true, runValidators: true }
        ).select('-password'); 

        if (!user) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }

        res.json({ success: true, message: 'Dersler başarıyla güncellendi.', courses: user.courses });

    } catch (err) {
        console.error("Ders Güncelleme Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

module.exports = router;