export const useSearch = () => {
	const { token } = useAuth();
	const config = useRuntimeConfig();

	// Advanced search with PostgreSQL full-text search
	const searchRecipes = async (searchParams: {
		query?: string;
		category?: string;
		difficulty?: string;
		max_prep_time?: number;
		max_cook_time?: number;
		ingredients?: string[];
		min_rating?: number;
		is_premium?: boolean;
		sort_by?: 'relevance' | 'newest' | 'popular' | 'rating' | 'prep_time';
		limit?: number;
		offset?: number;
	}) => {
		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					...(token.value && { Authorization: `Bearer ${token.value}` }),
				},
				body: {
					query: `
						query AdvancedSearchRecipes(
							$search_query: String
							$category_id: uuid
							$difficulty: String
							$max_prep_time: Int
							$max_cook_time: Int
							$ingredients: [String!]
							$min_rating: numeric
							$is_premium: Boolean
							$limit: Int
							$offset: Int
							$order_by: [recipes_order_by!]
						) {
							recipes(
								where: {
									_and: [
										{ is_published: { _eq: true } }
										${searchParams.query ? `{ _or: [
											{ title: { _ilike: $search_query } }
											{ description: { _ilike: $search_query } }
											{ ingredients: { name: { _ilike: $search_query } } }
										] }` : ''}
										${searchParams.category ? '{ category_id: { _eq: $category_id } }' : ''}
										${searchParams.difficulty ? '{ difficulty: { _eq: $difficulty } }' : ''}
										${searchParams.max_prep_time ? '{ prep_time: { _lte: $max_prep_time } }' : ''}
										${searchParams.max_cook_time ? '{ cook_time: { _lte: $max_cook_time } }' : ''}
										${searchParams.min_rating ? '{ average_rating: { _gte: $min_rating } }' : ''}
										${searchParams.is_premium !== undefined ? '{ is_premium: { _eq: $is_premium } }' : ''}
										${searchParams.ingredients?.length ? `{ ingredients: { name: { _in: $ingredients } } }` : ''}
									]
								}
								limit: $limit
								offset: $offset
								order_by: $order_by
							) {
								id
								title
								description
								prep_time
								cook_time
								servings
								difficulty
								featured_image_url
								is_premium
								price
								created_at
								average_rating
								total_likes
								total_comments
								user {
									id
									username
									full_name
									avatar_url
								}
								category {
									id
									name
									slug
								}
							}
							
							recipes_aggregate(
								where: {
									_and: [
										{ is_published: { _eq: true } }
										${searchParams.query ? `{ _or: [
											{ title: { _ilike: $search_query } }
											{ description: { _ilike: $search_query } }
											{ ingredients: { name: { _ilike: $search_query } } }
										] }` : ''}
										${searchParams.category ? '{ category_id: { _eq: $category_id } }' : ''}
										${searchParams.difficulty ? '{ difficulty: { _eq: $difficulty } }' : ''}
										${searchParams.max_prep_time ? '{ prep_time: { _lte: $max_prep_time } }' : ''}
										${searchParams.max_cook_time ? '{ cook_time: { _lte: $max_cook_time } }' : ''}
										${searchParams.min_rating ? '{ average_rating: { _gte: $min_rating } }' : ''}
										${searchParams.is_premium !== undefined ? '{ is_premium: { _eq: $is_premium } }' : ''}
										${searchParams.ingredients?.length ? `{ ingredients: { name: { _in: $ingredients } } }` : ''}
									]
								}
							) {
								aggregate {
									count
								}
							}
						}
					`,
					variables: {
						search_query: searchParams.query ? `%${searchParams.query}%` : null,
						category_id: searchParams.category || null,
						difficulty: searchParams.difficulty || null,
						max_prep_time: searchParams.max_prep_time || null,
						max_cook_time: searchParams.max_cook_time || null,
						ingredients: searchParams.ingredients || null,
						min_rating: searchParams.min_rating || null,
						is_premium: searchParams.is_premium,
						limit: searchParams.limit || 12,
						offset: searchParams.offset || 0,
						order_by: getOrderBy(searchParams.sort_by || 'relevance'),
					},
				},
			});

			return {
				recipes: data?.recipes || [],
				total: data?.recipes_aggregate?.aggregate?.count || 0,
			};
		} catch (error) {
			console.error("Search failed:", error);
			return {
				recipes: [],
				total: 0,
				error: error.message || "Search failed",
			};
		}
	};

	// Get search suggestions
	const getSearchSuggestions = async (query: string) => {
		if (!query || query.length < 2) return [];

		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: {
					query: `
						query GetSearchSuggestions($search_query: String!) {
							recipes(
								where: {
									_and: [
										{ is_published: { _eq: true } }
										{ title: { _ilike: $search_query } }
									]
								}
								limit: 5
								order_by: { total_likes: desc }
							) {
								id
								title
								featured_image_url
							}
							
							recipe_ingredients(
								where: { name: { _ilike: $search_query } }
								distinct_on: name
								limit: 5
							) {
								name
							}
							
							categories(
								where: { name: { _ilike: $search_query } }
								limit: 3
							) {
								id
								name
								slug
							}
						}
					`,
					variables: {
						search_query: `%${query}%`,
					},
				},
			});

			return {
				recipes: data?.recipes || [],
				ingredients: data?.recipe_ingredients?.map(i => i.name) || [],
				categories: data?.categories || [],
			};
		} catch (error) {
			console.error("Failed to get search suggestions:", error);
			return {
				recipes: [],
				ingredients: [],
				categories: [],
			};
		}
	};

	// Get popular search terms
	const getPopularSearchTerms = async () => {
		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: {
					query: `
						query GetPopularSearchTerms {
							search_logs(
								order_by: { count: desc }
								limit: 10
								where: { created_at: { _gte: "now() - interval '30 days'" } }
							) {
								search_term
								count
							}
						}
					`,
				},
			});

			return data?.search_logs?.map(log => log.search_term) || [];
		} catch (error) {
			console.error("Failed to get popular search terms:", error);
			return [];
		}
	};

	// Log search query for analytics
	const logSearch = async (query: string, resultsCount: number) => {
		try {
			await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					...(token.value && { Authorization: `Bearer ${token.value}` }),
				},
				body: {
					query: `
						mutation LogSearch($search_term: String!, $results_count: Int!) {
							insert_search_logs_one(
								object: { 
									search_term: $search_term, 
									results_count: $results_count 
								}
								on_conflict: {
									constraint: search_logs_search_term_key,
									update_columns: [count, updated_at]
								}
							) {
								id
							}
						}
					`,
					variables: {
						search_term: query,
						results_count: resultsCount,
					},
				},
			});
		} catch (error) {
			console.error("Failed to log search:", error);
		}
	};

	const getOrderBy = (sortBy: string) => {
		switch (sortBy) {
			case 'newest':
				return [{ created_at: 'desc' }];
			case 'popular':
				return [{ total_likes: 'desc' }, { created_at: 'desc' }];
			case 'rating':
				return [{ average_rating: 'desc' }, { created_at: 'desc' }];
			case 'prep_time':
				return [{ prep_time: 'asc' }];
			case 'relevance':
			default:
				return [{ total_likes: 'desc' }, { average_rating: 'desc' }, { created_at: 'desc' }];
		}
	};

	return {
		searchRecipes,
		getSearchSuggestions,
		getPopularSearchTerms,
		logSearch,
	};
};