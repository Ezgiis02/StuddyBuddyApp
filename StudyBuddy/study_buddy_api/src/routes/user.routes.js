// src/routes/user.routes.js

const express = require('express');
const router = express.Router();
const User = require('../models/user.model');
const { protect } = require('../middleware/auth.middleware');

// Bu rotalar yetkilendirme (token) gerektirir.

// @route   PUT /api/users/rate
// @desc    Bir kullanıcıyı puanlama (1-5 yıldız)
// @access  Private
router.put('/rate', protect, async (req, res) => {
    const { targetUserId, newRating } = req.body; // Puanlanacak kullanıcı ID'si ve yeni puan

    if (!targetUserId || typeof newRating !== 'number' || newRating < 1 || newRating > 5) {
        return res.status(400).json({ success: false, message: 'Geçerli bir kullanıcı ID\'si ve 1-5 arasında puan girin.' });
    }

    try {
        const user = await User.findById(targetUserId);

        if (!user) {
            return res.status(404).json({ success: false, message: 'Puanlanacak kullanıcı bulunamadı.' });
        }

        // Ortalama Puan Hesaplama: Yeni puanı ve puan sayısını ekleyerek ortalamayı bulma
        const newRatingCount = user.ratingCount + 1;
        // Mevcut toplam puan: user.rating * user.ratingCount
        const newTotalRating = (user.rating * user.ratingCount) + newRating;
        const finalRating = newTotalRating / newRatingCount;

        user.rating = finalRating;
        user.ratingCount = newRatingCount;
        await user.save();

        res.json({ 
            success: true, 
            message: 'Kullanıcı başarıyla puanlandı.', 
            newAvgRating: finalRating.toFixed(1) 
        });

    } catch (err) {
        console.error("Puanlama Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

// @route   PUT /api/users/favorite
// @desc    Kullanıcıyı favori listesine ekle/çıkar
// @access  Private
router.put('/favorite', protect, async (req, res) => {
    const { targetUserId, action } = req.body; // 'add' veya 'remove'

    if (!targetUserId || !['add', 'remove'].includes(action)) {
        return res.status(400).json({ success: false, message: 'Geçerli bir kullanıcı ID\'si ve \'add\' veya \'remove\' eylemi girin.' });
    }

    try {
        const userId = req.userId; // İşlemi yapan kullanıcı

        let user;
        if (action === 'add') {
            // Favori listesine ekle ($addToSet duplicate kaydı engeller)
            user = await User.findByIdAndUpdate(
                userId, 
                { $addToSet: { favorites: targetUserId } },
                { new: true }
            );
            res.json({ success: true, message: 'Kullanıcı favorilere eklendi.' });
        } else {
            // Favori listesinden çıkar
            user = await User.findByIdAndUpdate(
                userId, 
                { $pull: { favorites: targetUserId } },
                { new: true }
            );
            res.json({ success: true, message: 'Kullanıcı favorilerden çıkarıldı.' });
        }

    } catch (err) {
        console.error("Favori Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

// @route   GET /api/users/matches
// @desc    Kullanıcının ders eşleşmelerini ve gelen istekleri getir
// @access  Private
router.get('/matches', protect, async (req, res) => {
  try {
    const userId = req.userId; // Middleware'den gelen kullanıcı ID'si

    // 1. Giriş yapan kullanıcının seçtiği dersleri ve listelerini al
    const currentUser = await User.findById(userId).select('courses favorites pendingRequests incomingRequests');

    if (!currentUser) {
      return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
    }

    if (!currentUser.courses || currentUser.courses.length === 0) {
      return res.json({ 
        success: true, 
        matches: [], 
        incomingRequests: [], 
        message: 'Eşleşme bulmak için önce ders seçmelisiniz.' 
      });
    }

    const userCourses = currentUser.courses;
    
    // 2. Filtreleme: Sadece pendingRequests ve favorites listelerindeki kişileri çıkar
    // incomingRequests'i çıkarma (çünkü onlar Ana Sayfa'da görünecek)
    const ignoredUsers = [
      userId, 
      ...currentUser.favorites, 
      ...currentUser.pendingRequests
      // incomingRequests'i kaldırdık - artık Ana Sayfa'da görünecekler
    ];

    // 3. Bu derslerden en az birine sahip, filtrelenmemiş diğer kullanıcılar
    const matches = await User.find({
      _id: { $nin: ignoredUsers },
      courses: { $in: userCourses },
    }).select('-password');

    // 4. Gelen istekler (incomingRequests) kullanıcı detaylarıyla
    const incomingRequests = await User.find({
      _id: { $in: currentUser.incomingRequests },
    }).select('-password');

    res.json({
      success: true,
      matches: matches,
      incomingRequests: incomingRequests
    });

  } catch (err) {
    console.error("Eşleşme Hatası:", err.message);
    res.status(500).json({ success: false, message: 'Sunucu hatası.' });
  }
});

// @route   POST /api/users/send-request
// @desc    Çalışma isteği gönderme
// @access  Private
router.post('/send-request', protect, async (req, res) => {
    const { targetUserId } = req.body;
    const senderId = req.userId;

    if (!targetUserId) {
        return res.status(400).json({ success: false, message: 'Hedef kullanıcı ID\'si zorunludur.' });
    }

    try {
        // 1. Gönderenin listesine ekle (pendingRequests)
        await User.findByIdAndUpdate(
            senderId, 
            { $addToSet: { pendingRequests: targetUserId } }
        );

        // 2. Alıcının listesine ekle (incomingRequests)
        await User.findByIdAndUpdate(
            targetUserId,
            { $addToSet: { incomingRequests: senderId } }
        );

        res.json({ success: true, message: 'Çalışma isteği başarıyla gönderildi.' });

    } catch (err) {
        console.error("İstek Gönderme Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

// @route   POST /api/users/handle-request
// @desc    Çalışma isteğini kabul etme veya reddetme
// @access  Private
router.post('/handle-request', protect, async (req, res) => {
    const { senderId, action } = req.body; // action: 'accept' veya 'reject'
    const receiverId = req.userId;

    if (!senderId || !['accept', 'reject'].includes(action)) {
        return res.status(400).json({ success: false, message: 'Gönderen ID\'si ve geçerli eylem zorunludur.' });
    }

    try {
        // Her iki kullanıcıdan da istekleri kaldır
        await User.findByIdAndUpdate(receiverId, { $pull: { incomingRequests: senderId } });
        await User.findByIdAndUpdate(senderId, { $pull: { pendingRequests: receiverId } });

        if (action === 'accept') {
            // Karşılıklı olarak Favorilere (Eşleşilenlere) ekle
            await User.findByIdAndUpdate(receiverId, { $addToSet: { favorites: senderId } });
            await User.findByIdAndUpdate(senderId, { $addToSet: { favorites: receiverId } });

            return res.json({ success: true, message: 'İstek kabul edildi ve favorilere eklendi.' });
        } else {
            return res.json({ success: true, message: 'İstek reddedildi.' });
        }
    } catch (err) {
        console.error("İstek İşleme Hatası:", err.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

module.exports = router;