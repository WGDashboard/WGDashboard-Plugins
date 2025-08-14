<script setup lang="ts">

import Stars from "~/components/stars.vue";

const githubSponsors = ref([])
$fetch("/api/sponsors").then(res => {
	githubSponsors.value = res.data.user.sponsorshipsAsMaintainer.nodes
})
</script>

<template>
	<div class="container d-flex flex-column gap-4 blurIn">
		<h1 class="display-5 fw-bold">This project is sponsored by</h1>
		<a href="https://m.do.co/c/a84cb9aac585">
			<img
				alt="DigitalOcean Logo"
				width="300px"
				src="/DO_Logo_Horizontal_Blue.png">
		</a>
		<h4 class="fw-normal">
			and
		</h4>
		<div>
			<div v-for="u in githubSponsors"
			     class="d-inline-block me-3 shadow">
				<a :href="'https://github.com/' + u.sponsorEntity.login">
					<img alt="icon"
					     class="border"
					     :src="u.sponsorEntity.avatarUrl" width="70px"
					     style="border-radius: 100%">
				</a>
			</div>
		</div>
		<h4 class="fw-normal">
			from GitHub. <strong>Thank you all!</strong>
		</h4>
		<GoogleAds width="100%" height="200px" class="mt-3" data-ad-slot="4115572421"></GoogleAds>
	</div>
</template>

<style scoped>

</style>