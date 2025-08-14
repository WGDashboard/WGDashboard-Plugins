<script setup lang="ts">
const slides = [
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/index.png",
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/sign-in.png",
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/cross-server.png",
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/new-configuration.png" ,
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/settings.png" ,
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/light-dark.png" ,
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/configuration.png",
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/add-peers.png" ,
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/ping.png",
	"https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/traceroute.png",
]

const curIndex = ref(0)

</script>

<template>
<div>
	<NuxtImg
		class="w-100 rounded-4"
		v-slot="{ src, isLoaded, imgAttrs }"
		preload
		:custom="true"
		:src="slides[0]" alt="WGDashboard Index Screenshot">
		<transition name="fade">
			<img
				v-if="isLoaded"
				v-bind="imgAttrs"
				:src="src"
				class="blurIn"
				alt="">
			<div
				v-else
				class="w-100 rounded-4 border border-1"
				style="padding-top: 56.22%;"
			>
			</div>
		</transition>
	</NuxtImg>
</div>
</template>

<style scoped>

</style>