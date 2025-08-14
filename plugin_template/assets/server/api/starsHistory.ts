import dayjs from "dayjs";
export default defineEventHandler(async () => {
    interface s {
        date: number
    }
    const starsHistory: Array<string> | undefined = await useStorage('local').get('starHistory') as Array<string>
    const dateCount: { string: number } = {}

    starsHistory.forEach((x: string) => {
        let date = dayjs(x)
        let key = date.format("YYYY-MM-DD")
        if (Object.keys(dateCount).includes(key)){
            dateCount[key] += 1
        }else{
            dateCount[key] = 1
        }
    })
    let cumulativeHistory = []
    for (let i of Object.keys(dateCount)){
        if (cumulativeHistory.length === 0){
            cumulativeHistory.push(dateCount[i])
        }else{
            cumulativeHistory.push(
                cumulativeHistory[cumulativeHistory.length - 1] + dateCount[i]
            )
        }
    }


    return {
        keys: Object.keys(dateCount),
        values: cumulativeHistory
    }
})