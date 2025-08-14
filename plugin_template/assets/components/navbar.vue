<script setup lang="ts">

const bg = ref(false)

onMounted(() => {
	let logo = document.querySelector<HTMLElement>('.wgdLogo');
	if (logo){
		bg.value = window.scrollY > (logo.offsetTop - 50)
		document.addEventListener('scroll', () => {
			bg.value = window.scrollY > (logo.offsetTop - 50)
		})
	}
})

</script>

<template>
	<nav class="navbar navbar-expand blurInDown sticky-top" :class="{'navbarBg': bg}">
		<div class="container-fluid">
			<a class="navbar-brand" href="#">
				<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Logos/Logo-2-Rounded-128x128.png" alt="WGDashboard-Logo" width="30">
			</a>
			<ul class="navbar-nav ms-auto ">
				<li class="nav-item">
					<a class="nav-link"
					   target="_blank"
					   aria-label="Documentation"
					   href="https://docs.wgdashboard.dev/index_topic.html">
						<i class="bi bi-book-fill me-2"></i>
						<span>Documentation</span>
					</a>
				</li>
				<li class="nav-item">
					<a class="nav-link"
					   target="_blank"
					   aria-label="APIs"
					   href="https://docs.wgdashboard.dev/api-documentation.html">
						<i class="bi bi-key-fill me-2"></i>
						<span>APIs</span>
					</a>
				</li>
				<li class="nav-item">
					<a class="nav-link"
					   target="_blank"
					   aria-label="GitHub"
					   href="https://github.com/donaldzou/WGDashboard">
						<i class="bi bi-github me-2"></i>
						<span>GitHub</span>
					</a>
				</li>
				<li class="nav-item">
					<a class="nav-link"
					   target="_blank"
					   aria-label="Merch from WGDashboard"
					   href="https://merch.wgdashboard.dev">
						<i class="bi bi-tag-fill me-2"></i>
						<span>Merch</span>
					</a>
				</li>

			</ul>
		</div>
	</nav>
</template>

<style scoped>
.nav-link{
	color: var(--bs-body-color)
}

@media screen and (max-width: 576px) {
	.nav-link span{
		display: none;
	}
}
</style>