const express = require('express')
const router = express.Router()
const fetch = require('node-fetch');
const url = 'https://covid19.mathdro.id/api'
const controller = require('../controller/controller')

router.get('/',controller.getSuburbPerformanceStatisticsDataBySuburb , function(req,res){
    res.render('home', { data: res.response })
})

module.exports = router
