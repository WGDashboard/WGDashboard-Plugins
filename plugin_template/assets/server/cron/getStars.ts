import { defineCronHandler } from '#nuxt/cron'
import axios from "axios";

export default defineCronHandler('hourly', async () => {
    // await useStorage('local').set('stars', [{hi: 123}])
    // const currentStars = await useStorage('local').get('stars')
    interface Star{
        starred_at: number
    }

    let newStars: Array<Object> = []
    const generalInformation = await axios.get("https://api.github.com/repos/donaldzou/WGDashboard", {
        headers: {
            'Content-Type': 'application/json',
            "Authorization": `bearer ${process.env.GITHUB_TOKEN}`
        }
    })

    if (generalInformation){
        const perPage = 100
        const numberOfPages = Math.ceil(generalInformation.data.watchers / perPage)
        console.log(numberOfPages)
        for (let page = 1; page <= numberOfPages; page++){
            console.log(`https://api.github.com/repos/donaldzou/WGDashboard/stargazers?per_page=${perPage}&page=${page}`)
            const s = await axios.get(
            	`https://api.github.com/repos/donaldzou/WGDashboard/stargazers?per_page=${perPage}&page=${page}`,
            	{
            		headers: {
                        'Accept': 'application/vnd.github.star+json',
            			'Content-Type': 'application/json',
            			"Authorization": `bearer ${process.env.GITHUB_TOKEN}`
            		}
            	}
            )
            if (s){
                newStars = newStars.concat(s.data.map((x : Star) => x.starred_at))
            }
        }

        await useStorage('local').set('starHistory', newStars)
        console.log("Stars Refreshed")
    }
}, { runOnInit: true })