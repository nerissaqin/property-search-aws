
const fetch = require('node-fetch');
const base_url='https://api.domain.com.au'
const location_api=`${base_url}/v1/addressLocators`
const statistic_api=`${base_url}/v1/suburbPerformanceStatistics`
const api_gateway_save_data_api=`https://p1zo44xthf.execute-api.us-east-1.amazonaws.com/save-client-data`
const key = 'key_7350b1b8c5cb3276eb9bf4993004e150'


async function getSuburbPerformanceStatistics (suburb, state, res) {
    let response
    let json
    let suburbId = await getLocationId(suburb, state, res)
    if (suburbId == null) {
        return {errMessage: "Can't find the suburb with the suburb and state that provided. Please try again.", suburb, state}
    }
    let params = new URLSearchParams({
        state,
        suburbId,
        propertyCategory: 'house',
        chronologicalSpan: 12,
        tPlusFrom: 1,
        tPlusTo: 1
    })

    try{
        response = await fetch(
            `${statistic_api}?${params}`,
            {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Api-Key' : key,
                }
            }
        )
        json = await response.json()
        console.log(json)

        if (json == null) {
            return res.status(404).json({message:err.message.value})
        }


    } catch (err) {
        return res.status(500).json({message:err.message})
    }
    const data = {...json.series.seriesInfo[0], ...json.header}
    return data
}

async function getLocationId (suburb, state, res){
    let response
    let json
    let params = new URLSearchParams({
        searchLevel: 'suburb',
        suburb: suburb,
        state: state,
    })

    try{
        response = await fetch(
            `${location_api}?${params}`,
            {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Api-Key' : key,
                }
            }
        )
        json = await response.json()
        // console.log(json[0].ids[0].id)

        if (json == null) {
            return null
        }

        if (json[0] == null) {
            return null
        }


    } catch (err) {
        return res.status(500).json({message:err.message})
    }

    return json[0].ids[0].id
}
async function saveClientData (suburb, state){
    let response
    let json
    let params = new URLSearchParams({
        suburb,
        state
    })

    try{
        response = await fetch(
            `${api_gateway_save_data_api}?${params}`,
            {
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        )
        json = await response.json()

        if (json == null) {
            return null
        }
    } catch (err) {
        return res.status(500).json({message:err.message})
    }

    return "done"
}

async function getSuburbPerformanceStatisticsDataBySuburb (req,res,next){
    // todo collect data
    console.log({suburb: req.body.suburb, state: req.body.state, ip: req.headers['x-forwarded-for'] || req.socket.remoteAddress })
    res.response = await getSuburbPerformanceStatistics(req.body.suburb, req.body.state, res)
    await saveClientData(req.body.suburb, req.body.state)
    next()
}



module.exports.getSuburbPerformanceStatisticsDataBySuburb = getSuburbPerformanceStatisticsDataBySuburb


