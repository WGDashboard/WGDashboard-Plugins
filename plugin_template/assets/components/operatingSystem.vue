<script setup lang="ts">

</script>

<template>
	<div class="d-flex flex-column gap-4">
		<h4 class="fw-normal">
			It can run on
		</h4>
		<div class="row g-2">
			<div class="col-sm-12">
				<a
					href="https://docs.wgdashboard.dev/install.html#option-2-install-wgdashboard-with-a-command"
					target="_blank"
					class="card rounded-4 text-center shadow openInModal">
					<div class="card-body p-4">
						<h1>
							<i class="bi bi-tux"></i>
						</h1>
						<h5>
							Bare-Metal on Linux
						</h5>
						<p class="text-muted mb-0">
							Supports Ubuntu, Debian, RHEL, CentOS, AlmaLinux, Fedora, Alpine Linux, Rocky Linux & Raspberry Pi OS
						</p>
					</div>
				</a>
			</div>
			<div class="col-sm">
				<a href="https://github.com/donaldzou/WGDashboard/blob/main/docker/README.md"
				   target="_blank" class="card rounded-4 shadow">
					<div class="card-body text-center p-4">
						<h1>
							<i class="bi bi-cloud-fill"></i>
						</h1>
						<h5>
							Docker
						</h5>
						<p class="text-muted mb-0">
							Thanks to our incredible contributor @DaanSelen
						</p>
					</div>
				</a>
			</div>
			<div class="col-sm">
				<a href="https://community-scripts.github.io/ProxmoxVE/scripts?id=wireguard"
				   target="_blank" class="card rounded-4 shadow">
					<div class="card-body text-center p-4">
						<h1>
							<i class="bi bi-server"></i>
						</h1>
						<h5>
							Proxmox
						</h5>
						<p class="text-muted mb-0">
							Proxmox community got a script to run WGDashboard
						</p>
					</div>
				</a>
			</div>
		</div>
	</div>
</template>

<style scoped>

</style>