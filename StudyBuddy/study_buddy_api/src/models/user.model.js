// src/models/user.model.js

// Gerekli paketi dosyanın EN ÜSTÜNE import ediyoruz
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); 

const UserSchema = new mongoose.Schema({
    // ... Şema Alanlarınız Buraya Geliyor ...
    name: {
        type: String,
        required: [true, 'Ad ve Soyad zorunludur.'],
        trim: true
    },
    email: {
        type: String,
        required: [true, 'E-posta zorunludur.'],
        unique: true, 
        lowercase: true 
    },
    password: {
        type: String,
        required: [true, 'Şifre zorunludur.'],
        minlength: [6, 'Şifre en az 6 karakter olmalıdır.']
    },
    courses: [
        {
            type: String, 
            trim: true
        }
    ],
    rating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    ratingCount: {
        type: Number,
        default: 0
    },

    favorites: [ // <-- YENİ EKLENEN KISIM
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    ],
    pendingRequests: [ // Kullanıcının gönderdiği istekler (beklemede)
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    ],
    incomingRequests: [ // Kullanıcının aldığı istekler
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    ],
    profilePicture: {
        type: String,
        default: 'default.jpg' 
    },
    darkMode: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Şifreleme Mantığı: Kaydetme işleminden hemen önce çalışacak
UserSchema.pre('save', async function(next) {
    // Şifre değiştirilmemişse veya yeni bir kayıt değilse hash'leme
    if (!this.isModified('password')) {
        return next(); // 'next()' kullanımı düzeltildi
    }
    // Tuzlama (salt) oluştur ve şifreyi hash'le
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});


// Modeli dışa aktar
const User = mongoose.model('User', UserSchema);
module.exports = User;