<script setup>
const props = defineProps(['width', 'height', 'dataAdSlot'])

onMounted(() => {
	if (import.meta.client && window.adsbygoogle) {
		try {
			(window.adsbygoogle = window.adsbygoogle || []).push({});
			console.log("Loaded GoogleAds")
		} catch (e) {
			console.error('AdSense error:', e);
		}
	}
})
</script>

<template>
	<div>
		<ins class="adsbygoogle"
		     style="display:block"
		     data-full-width-responsive="true"
		     :style="{width: width, height: height}"
		     data-ad-client="ca-pub-2283617751904576"
		     :data-ad-slot="dataAdSlot"></ins>
	</div>
</template>

<style scoped></style>