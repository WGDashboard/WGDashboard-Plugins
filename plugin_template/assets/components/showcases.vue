<script setup lang="ts">
const showcases = ref([
	{
		url: 'https://www.youtube.com/embed/cxHwVsgVKRA?si=onvsL970wt8hVuNT',
		title: 'Tailscale o WireGuard para VPN en tu VPS? AMBOS!',
		author: 'Jonatan Castro',
		origin: 'YouTube'
	},
	{
		url: 'https://player.bilibili.com/player.html?isOutside=true&aid=113334590377944&bvid=BV1CMCfY9Ek7&cid=26367495763&p=1',
		title: '从零开始：WGDashboard面板介绍、安装与WireGuard管理全攻略',
		author: '抓單的灰太狼',
		origin: 'Bilibili'
	},
	{
		url: 'https://www.youtube.com/embed/OVelAzQRigk?si=D8GPw5w5UsnJwyLU',
		title: 'Setup Wireguard and WGDashboard using Proxmox VE Helper-Scripts',
		author: 'Ziggy Puppy Productions',
		origin: 'YouTube'
	},
	{
		url: 'https://www.youtube.com/embed/hF9QQiqYRDI?si=wiUa7v4x_dxQIVRs',
		title: 'The Ultimate Guide to WireGuard on Proxmox with New Helper Scripts',
		author: 'Barmine Tech',
		origin: 'YouTube'
	}
])
</script>

<template>
	<div class="container d-flex flex-column gap-4 blurIn">
		<h1 class="display-5 fw-bold">Showcases</h1>
		<h4 class="fw-normal">
			from creators across the globe about WGDashboard. <span class="fw-bold">Thank you all!</span>
		</h4>
		<div class="row g-3">
			<div class="col-sm-4" v-for="video in showcases">
				<div>
					<iframe width="100%"
					        class="mb-2"
					        style="aspect-ratio: 16/9"
					        :src="video.url" title="YouTube video player" allowfullscreen></iframe>
					<h6 class="mb-0 fw-bold">{{ video.title }}</h6>
					<small>by @{{video.author}} from {{ video.origin }}</small>
				</div>
			</div>
			<div class="col-sm-4">
				<div class="w-100 d-flex border d-flex"
				     style="aspect-ratio: 16/9">
					<h6 class="m-auto text-center">
						<span class="spinner-border mb-3"></span><br>
						Loading for more...
					</h6>
				</div>
			</div>
		</div>
	</div>
</template>

<style scoped>

</style>