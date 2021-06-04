const Chance = require('chance')
const chance = new Chance()

const express = require('express')
const app = express()

const port = 3000

app.get('/', (req, res) => {
    res.send( generateData() )
})

app.listen(port, () => {
    console.log(`Accept HTTP GET requests on port 3000 `)
})

function generateData(){
    let dataNb = chance.integer({
        min: 0,
        max: 10
    })

    let data = []
    
    for(let i = 0; i < dataNb; ++i){
        data.push({
            animal: chance.animal(),
            profession: chance.profession(),
            gender: chance.gender()
        })
    }
    return data
}