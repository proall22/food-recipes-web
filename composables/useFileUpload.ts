export const useFileUpload = () => {
	const uploading = ref(false);
	const uploadProgress = ref(0);
	const { token } = useAuth();
	const config = useRuntimeConfig();

	const uploadFile = async (
		file: File
	): Promise<{ url: string; key: string } | null> => {
		uploading.value = true;
		uploadProgress.value = 0;

		try {
			// Validate file
			if (!file) {
				throw new Error('No file provided');
			}

			// Validate file type
			const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
			if (!allowedTypes.includes(file.type)) {
				throw new Error('Invalid file type. Only images are allowed.');
			}

			// Validate file size (max 10MB)
			if (file.size > 10 * 1024 * 1024) {
				throw new Error('File size too large. Maximum 10MB allowed.');
			}

			const formData = new FormData();
			formData.append("file", file);

			const response = await $fetch(`${config.public.backendUrl}/api/v1/files/upload`, {
				method: "POST",
				body: formData,
				headers: {
					Authorization: `Bearer ${token.value}`,
				},
				onUploadProgress: (progress) => {
					if (progress.total) {
						uploadProgress.value = Math.round(
							(progress.loaded * 100) / progress.total
						);
					}
				},
			});

			if (response && response.url && response.key) {
				return {
					url: response.url,
					key: response.key,
				};
			} else {
				throw new Error('Invalid response from server');
			}
		} catch (error: any) {
			console.error("Upload failed:", error);
			
			// Provide user-friendly error messages
			let errorMessage = "Upload failed. Please try again.";
			if (error.message) {
				errorMessage = error.message;
			} else if (error.data?.error) {
				errorMessage = error.data.error;
			}
			
			throw new Error(errorMessage);
		} finally {
			uploading.value = false;
			uploadProgress.value = 0;
		}
	};

	const uploadMultipleFiles = async (files: File[]): Promise<Array<{ url: string; key: string }>> => {
		const results = [];
		
		for (const file of files) {
			try {
				const result = await uploadFile(file);
				if (result) {
					results.push(result);
				}
			} catch (error) {
				console.error(`Failed to upload ${file.name}:`, error);
				// Continue with other files even if one fails
			}
		}
		
		return results;
	};

	const deleteFile = async (key: string): Promise<boolean> => {
		try {
			await $fetch(`${config.public.backendUrl}/api/v1/files/${key}`, {
				method: "DELETE",
				headers: {
					Authorization: `Bearer ${token.value}`,
				},
			});
			return true;
		} catch (error) {
			console.error("Delete failed:", error);
			return false;
		}
	};

	const getFileUrl = (key: string): string => {
		// Construct S3 URL from key
		return `https://recipe-images.s3.amazonaws.com/${key}`;
	};

	const validateImageFile = (file: File): { valid: boolean; error?: string } => {
		const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
		const maxSize = 10 * 1024 * 1024; // 10MB

		if (!allowedTypes.includes(file.type)) {
			return {
				valid: false,
				error: 'Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed.'
			};
		}

		if (file.size > maxSize) {
			return {
				valid: false,
				error: 'File size too large. Maximum 10MB allowed.'
			};
		}

		return { valid: true };
	};

	return {
		uploading: readonly(uploading),
		uploadProgress: readonly(uploadProgress),
		uploadFile,
		uploadMultipleFiles,
		deleteFile,
		getFileUrl,
		validateImageFile,
	};
};