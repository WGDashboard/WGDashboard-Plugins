
export default defineEventHandler(async (event) => {
    let body = `
        query {
            user(login: "donaldzou") {
                sponsorshipsAsMaintainer(
                    activeOnly: false, 
                    first: 10,
                    orderBy: { field: CREATED_AT, direction: ASC }
                ) {
                    totalCount
                    nodes {
                        sponsorEntity {
                            ... on User {
                                login,
                                avatarUrl
                            }
                            ... on Organization {
                                login
                            }
                        }
                    }
                }
            }
        }
    `

    const request = await fetch("https://api.github.com/graphql", {
        method: "POST",
        body: JSON.stringify({ query: body }),
        headers: {
            'Content-Type': 'application/json',
            "Authorization": `bearer ${process.env.GITHUB_TOKEN}`
        }
    })
    return await request.json()
})