const express = require('express')
const router = express.Router()
const fetch = require('node-fetch');
const url = 'https://covid19.mathdro.id/api'
const controller = require('../controller/controller')

router.post('/',controller.getSuburbPerformanceStatisticsDataBySuburb , function(req,res){
    res.render('suburb', { data: res.response })
})

router.get('/', function(req,res){
    res.render('home')
})

module.exports = router

