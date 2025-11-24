// src/models/course.model.js

const mongoose = require('mongoose');

const CourseSchema = new mongoose.Schema({
    // Örneğin: "CS301", "MATH101"
    code: {
        type: String,
        required: true,
        unique: true,
        trim: true,
    },
    // Örneğin: "Algoritmalar ve Veri Yapıları"
    name: {
        type: String,
        required: true,
        trim: true,
    },
    // Dersin hangi fakülte/bölüme ait olduğu (filtreleme için)
    department: {
        type: String,
        required: true,
        trim: true,
    },
    // Dersin popülaritesi (kaç kişi seçtiği)
    studentCount: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

const Course = mongoose.model('Course', CourseSchema);
module.exports = Course;