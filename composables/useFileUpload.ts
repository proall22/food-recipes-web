export const useFileUpload = () => {
	const uploading = ref(false);
	const uploadProgress = ref(0);

	const uploadFile = async (
		file: File
	): Promise<{ url: string; key: string } | null> => {
		uploading.value = true;
		uploadProgress.value = 0;

		try {
			const formData = new FormData();
			formData.append("file", file);

			const { data } = await $fetch("/api/v1/files/upload", {
				method: "POST",
				body: formData,
				headers: {
					Authorization: `Bearer ${useAuth().token.value}`,
				},
				onUploadProgress: (progress) => {
					uploadProgress.value = Math.round(
						(progress.loaded * 100) / progress.total
					);
				},
			});

			return {
				url: data.url,
				key: data.key,
			};
		} catch (error) {
			console.error("Upload failed:", error);
			return null;
		} finally {
			uploading.value = false;
			uploadProgress.value = 0;
		}
	};

	const deleteFile = async (key: string): Promise<boolean> => {
		try {
			await $fetch(`/api/v1/files/${key}`, {
				method: "DELETE",
				headers: {
					Authorization: `Bearer ${useAuth().token.value}`,
				},
			});
			return true;
		} catch (error) {
			console.error("Delete failed:", error);
			return false;
		}
	};

	return {
		uploading: readonly(uploading),
		uploadProgress: readonly(uploadProgress),
		uploadFile,
		deleteFile,
	};
};
