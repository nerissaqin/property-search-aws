
const fetch = require('node-fetch');
const api_gateway_read_data_api=`https://p1zo44xthf.execute-api.us-east-1.amazonaws.com/read-client-data`


async function readClientData (suburb, state, res){
    let response
    let json

    try{
        response = await fetch(
            `${api_gateway_read_data_api}`,
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
    return json;
}

async function getSuburbPerformanceStatisticsDataBySuburb (req,res,next){
    let result = await readClientData(req.body.suburb, req.body.state, res)
    console.log(result)
    result.result.sort((a,b) =>{return b["count(1)"]-a["count(1)"]})
    console.log(result)
    res.response = result
    console.log(JSON.stringify(res.response))
    next()
}



module.exports.getSuburbPerformanceStatisticsDataBySuburb = getSuburbPerformanceStatisticsDataBySuburb


