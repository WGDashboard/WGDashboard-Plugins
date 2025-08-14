import { defineStore } from 'pinia'

export const store = defineStore('store', () => {
    const modal = ref(false)
    const modalSrc = ref("")

    return {modal, modalSrc}
})
