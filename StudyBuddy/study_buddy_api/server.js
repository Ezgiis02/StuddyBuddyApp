// server.js

const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors'); 

// Ortam değişkenlerini (.env dosyasını) yükle
dotenv.config();

// Rota dosyalarını içeri aktar
const authRoutes = require('./src/routes/auth.routes')
const courseRoutes = require('./src/routes/course.routes');
const userRoutes = require('./src/routes/user.routes');
// İleride buraya ders ve etüt rotaları eklenecek (Örn: const courseRoutes = require('./src/routes/course.routes'))

const app = express();

// --- CORS (Cross-Origin Resource Sharing) Yapılandırması ---
// Bu, Flutter web/mobil uygulamasının API'ye erişebilmesi için kritik.
// Localhost'taki tüm portlara izin vermek için esnek bir yapı kullanıyoruz.
const corsOptions = {
    // Regular Expression: localhost:XXXXX formatındaki tüm portlara izin verir.
    origin: (origin, callback) => {
        // origin yoksa (Örn: Postman/Thunder Client'tan doğrudan localhost isteği)
        // veya localhost'un herhangi bir portuysa (Flutter web)
        // veya mobil emülatör/simülatör IP'leri ise izin ver.
        if (!origin || origin.match(/^https?:\/\/localhost:(\d{4,5})$/) || 
            origin === 'http://10.0.2.2:3000' || 
            origin === 'http://127.0.0.1:3000') {
            callback(null, true);
        } else {
            // İleride, canlıya çıktığımızda sadece buraya 
            // canlı domain adını ekleyeceğiz.
            callback(new Error('Bu kaynaktan (origin) erişime izin verilmiyor.'));
        }
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
};

// CORS middleware'ini uygulamaya ekle
app.use(cors(corsOptions)); 

// Middleware'ler (Gelen JSON verilerini işlemek için)
// Bu, tüm rotalardan önce gelmelidir.
app.use(express.json());

// --- Rota Tanımlamaları ---
app.use('/api/auth', authRoutes); 
app.use('/api/courses', courseRoutes);
app.use('/api/users', userRoutes);
// İleride eklenecek: app.use('/api/courses', courseRoutes);

// Temel Test Rotası
app.get('/', (req, res) => {
    res.send('StudyBuddy API Çalışıyor!');
}); 


// --- MongoDB Bağlantısı ---
const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB bağlantısı başarılı!');
    } catch (err) {
        console.error('MongoDB bağlantı hatası:', err.message);
        process.exit(1); // Hata durumunda uygulamadan çık
    }
};

// Veritabanına bağlan ve sunucuyu başlat
connectDB().then(() => {
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
        console.log(`Sunucu http://localhost:${PORT} adresinde çalışıyor...`);
    });
});