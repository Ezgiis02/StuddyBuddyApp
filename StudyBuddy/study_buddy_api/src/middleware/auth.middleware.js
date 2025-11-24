// src/middleware/auth.middleware.js

const jwt = require('jsonwebtoken');
const JWT_SECRET = 'cok_gizli_anahtar'; // auth.routes.js dosyasındakiyle aynı olmalı!

const protect = (req, res, next) => {
    let token;

    // Token'ı başlık (header) içindeki Authorization alanından al
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // "Bearer <token>" kısmından sadece token'ı ayır
            token = req.headers.authorization.split(' ')[1];

            // Token'ı doğrula
            const decoded = jwt.verify(token, JWT_SECRET);

            // Çözülmüş kullanıcı ID'sini isteğe ekle
            req.userId = decoded.id; 
            
            next(); // Rotaya devam et
        } catch (error) {
            console.error(error);
            return res.status(401).json({ success: false, message: 'Yetkilendirme başarısız, token geçersiz.' });
        }
    }

    if (!token) {
        return res.status(401).json({ success: false, message: 'Erişim reddedildi, token bulunamadı.' });
    }
};

module.exports = { protect };