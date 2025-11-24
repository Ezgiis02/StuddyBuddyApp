// src/routes/course.routes.js

const express = require('express');
const router = express.Router();
const Course = require('../models/course.model');

// @route   POST /api/courses/add
// @desc    Yeni ders ekleme (Admin Paneli için düşünülmeli)
// @access  Public (Şimdilik test için public tutuyoruz)
router.post('/add', async (req, res) => {
    const { code, name, department } = req.body;
    try {
        const newCourse = new Course({ code, name, department });
        await newCourse.save();
        res.status(201).json({ success: true, course: newCourse });
    } catch (err) {
        // Genellikle benzersiz kod hatası verir (unique: true)
        res.status(400).json({ success: false, message: 'Ders kodu zaten mevcut veya eksik bilgi.' });
    }
});

// @route   GET /api/courses
// @desc    Tüm dersleri listeleme
// @access  Public
router.get('/', async (req, res) => {
    try {
        const courses = await Course.find().sort({ studentCount: -1 }); // Popülerliğe göre sırala
        res.json({ success: true, courses });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Sunucu hatası.' });
    }
});

module.exports = router;