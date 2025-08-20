import { useQuery, useMutation, useSubscription } from "@vue/apollo-composable";
import gql from "graphql-tag";

// Enhanced GraphQL Queries with proper Hasura integration
export const GET_RECIPES = gql`
	query GetRecipes(
		$limit: Int!
		$offset: Int!
		$where: recipes_bool_exp
		$order_by: [recipes_order_by!]
	) {
		recipes(
			limit: $limit
			offset: $offset
			where: $where
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
			updated_at
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
			ingredients {
				id
				name
				amount
				unit
				notes
			}
			steps {
				id
				step_number
				instruction
				image_url
			}
			images {
				id
				image_url
				is_featured
				caption
			}
		}
		recipes_aggregate(where: $where) {
			aggregate {
				count
			}
		}
	}
`;

export const GET_RECIPE_BY_ID = gql`
	query GetRecipeById($id: uuid!) {
		recipes_by_pk(id: $id) {
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
			is_published
			created_at
			updated_at
			average_rating
			total_likes
			total_comments
			user {
				id
				username
				full_name
				avatar_url
				bio
			}
			category {
				id
				name
				slug
			}
			ingredients {
				id
				name
				amount
				unit
				notes
			}
			steps {
				id
				step_number
				instruction
				image_url
			}
			images {
				id
				image_url
				is_featured
				caption
			}
		}
		
		# Track recipe view
		insert_recipe_views_one(object: { recipe_id: $id }) {
			id
		}
	}
`;

export const GET_USER_RECIPE_INTERACTIONS = gql`
	query GetUserRecipeInteractions($user_id: uuid!, $recipe_id: uuid!) {
		likes(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
		}
		bookmarks(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
		}
		ratings(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
			rating
		}
		purchases(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id }, status: { _eq: "completed" } }) {
			id
		}
	}
`;

export const GET_RECIPE_COMMENTS = gql`
	query GetRecipeComments($recipe_id: uuid!, $limit: Int!, $offset: Int!) {
		comments(
			where: { recipe_id: { _eq: $recipe_id }, parent_id: { _is_null: true } }
			order_by: { created_at: desc }
			limit: $limit
			offset: $offset
		) {
			id
			content
			created_at
			updated_at
			user {
				id
				username
				full_name
				avatar_url
			}
			replies: comments(order_by: { created_at: asc }) {
				id
				content
				created_at
				user {
					id
					username
					full_name
					avatar_url
				}
			}
		}
	}
`;

export const GET_CATEGORIES = gql`
	query GetCategories {
		categories(order_by: { name: asc }) {
			id
			name
			description
			icon
			slug
			recipes_aggregate {
				aggregate {
					count
				}
			}
		}
	}
`;

export const GET_POPULAR_RECIPES = gql`
	query GetPopularRecipes($limit: Int!) {
		get_popular_recipes(args: { limit_count: $limit }) {
			id
			title
			description
			prep_time
			cook_time
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
	}
`;

export const SEARCH_RECIPES = gql`
	query SearchRecipes($search_term: String!) {
		search_recipes(args: { search_term: $search_term }) {
			id
			title
			description
			prep_time
			cook_time
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
	}
`;

export const GET_USER_DASHBOARD_DATA = gql`
	query GetUserDashboardData($user_id: uuid!) {
		users_by_pk(id: $user_id) {
			id
			username
			full_name
			avatar_url
			bio
			recipe_count
		}
		
		user_recipes: recipes(
			where: { user_id: { _eq: $user_id } }
			order_by: { created_at: desc }
			limit: 5
		) {
			id
			title
			featured_image_url
			is_published
			total_likes
			average_rating
			created_at
		}
		
		user_bookmarks: bookmarks(
			where: { user_id: { _eq: $user_id } }
			order_by: { created_at: desc }
			limit: 5
		) {
			id
			created_at
			recipe {
				id
				title
				featured_image_url
				average_rating
				user {
					full_name
				}
			}
		}
		
		user_stats: users_by_pk(id: $user_id) {
			recipes_aggregate {
				aggregate {
					count
				}
			}
		}
		
		total_likes: likes_aggregate(where: { recipe: { user_id: { _eq: $user_id } } }) {
			aggregate {
				count
			}
		}
		
		bookmarks_count: bookmarks_aggregate(where: { user_id: { _eq: $user_id } }) {
			aggregate {
				count
			}
		}
	}
`;

// Real-time subscriptions
export const SUBSCRIBE_TO_RECIPE_LIKES = gql`
	subscription SubscribeToRecipeLikes($recipe_id: uuid!) {
		likes(where: { recipe_id: { _eq: $recipe_id } }) {
			id
			user_id
			created_at
		}
		likes_aggregate(where: { recipe_id: { _eq: $recipe_id } }) {
			aggregate {
				count
			}
		}
	}
`;

export const SUBSCRIBE_TO_RECIPE_COMMENTS = gql`
	subscription SubscribeToRecipeComments($recipe_id: uuid!) {
		comments(
			where: { recipe_id: { _eq: $recipe_id } }
			order_by: { created_at: desc }
		) {
			id
			content
			created_at
			user {
				id
				username
				full_name
				avatar_url
			}
		}
	}
`;

// Mutations
export const CREATE_RECIPE = gql`
	mutation CreateRecipe($recipe: recipes_insert_input!) {
		insert_recipes_one(object: $recipe) {
			id
			title
			created_at
		}
	}
`;

export const UPDATE_RECIPE = gql`
	mutation UpdateRecipe($id: uuid!, $updates: recipes_set_input!) {
		update_recipes_by_pk(pk_columns: { id: $id }, _set: $updates) {
			id
			title
			updated_at
		}
	}
`;

export const DELETE_RECIPE = gql`
	mutation DeleteRecipe($id: uuid!) {
		delete_recipes_by_pk(id: $id) {
			id
		}
	}
`;

export const LIKE_RECIPE = gql`
	mutation LikeRecipe($recipe_id: uuid!) {
		insert_likes_one(object: { recipe_id: $recipe_id }) {
			id
		}
	}
`;

export const UNLIKE_RECIPE = gql`
	mutation UnlikeRecipe($recipe_id: uuid!) {
		delete_likes(where: { recipe_id: { _eq: $recipe_id } }) {
			affected_rows
		}
	}
`;

export const BOOKMARK_RECIPE = gql`
	mutation BookmarkRecipe($recipe_id: uuid!) {
		insert_bookmarks_one(object: { recipe_id: $recipe_id }) {
			id
		}
	}
`;

export const REMOVE_BOOKMARK = gql`
	mutation RemoveBookmark($recipe_id: uuid!) {
		delete_bookmarks(where: { recipe_id: { _eq: $recipe_id } }) {
			affected_rows
		}
	}
`;

export const ADD_COMMENT = gql`
	mutation AddComment($recipe_id: uuid!, $content: String!, $parent_id: uuid) {
		insert_comments_one(object: { 
			recipe_id: $recipe_id, 
			content: $content,
			parent_id: $parent_id
		}) {
			id
			content
			created_at
			user {
				id
				username
				full_name
				avatar_url
			}
		}
	}
`;

export const RATE_RECIPE = gql`
	mutation RateRecipe($recipe_id: uuid!, $rating: Int!) {
		insert_ratings_one(
			object: { recipe_id: $recipe_id, rating: $rating }
			on_conflict: { 
				constraint: ratings_user_id_recipe_id_key, 
				update_columns: [rating, updated_at] 
			}
		) {
			id
			rating
		}
	}
`;

export const UPDATE_USER_PROFILE = gql`
	mutation UpdateUserProfile($id: uuid!, $updates: users_set_input!) {
		update_users_by_pk(pk_columns: { id: $id }, _set: $updates) {
			id
			username
			full_name
			avatar_url
			bio
			updated_at
		}
	}
`;

export const CREATE_PURCHASE = gql`
	mutation CreatePurchase($purchase: purchases_insert_input!) {
		insert_purchases_one(object: $purchase) {
			id
			transaction_id
			status
		}
	}
`;

export const UPDATE_PURCHASE_STATUS = gql`
	mutation UpdatePurchaseStatus($transaction_id: String!, $status: String!) {
		update_purchases(
			where: { transaction_id: { _eq: $transaction_id } }
			_set: { status: $status }
		) {
			affected_rows
		}
	}
`;

// Analytics queries
export const GET_RECIPE_ANALYTICS = gql`
	query GetRecipeAnalytics($recipe_id: uuid!) {
		recipe_views_aggregate(where: { recipe_id: { _eq: $recipe_id } }) {
			aggregate {
				count
			}
		}
		
		recipe_views(
			where: { recipe_id: { _eq: $recipe_id } }
			order_by: { created_at: desc }
			limit: 100
		) {
			id
			created_at
			user_id
		}
		
		likes_aggregate(where: { recipe_id: { _eq: $recipe_id } }) {
			aggregate {
				count
			}
		}
		
		comments_aggregate(where: { recipe_id: { _eq: $recipe_id } }) {
			aggregate {
				count
			}
		}
		
		ratings_aggregate(where: { recipe_id: { _eq: $recipe_id } }) {
			aggregate {
				avg {
					rating
				}
				count
			}
		}
	}
`;

// Composables for using GraphQL operations
export const useRecipes = () => {
	const getRecipes = (variables = { limit: 10, offset: 0 }) => {
		return useQuery(GET_RECIPES, variables, {
			errorPolicy: "all",
		});
	};

	const getRecipeById = (id) => {
		return useQuery(
			GET_RECIPE_BY_ID,
			{ id },
			{
				errorPolicy: "all",
				skip: !id,
			}
		);
	};

	const getPopularRecipes = (limit = 6) => {
		return useQuery(
			GET_POPULAR_RECIPES,
			{ limit },
			{
				errorPolicy: "all",
			}
		);
	};

	const searchRecipes = (searchTerm: string) => {
		return useQuery(
			SEARCH_RECIPES,
			{ search_term: searchTerm },
			{
				errorPolicy: "all",
			}
		);
	};

	const createRecipe = () => useMutation(CREATE_RECIPE);
	const updateRecipe = () => useMutation(UPDATE_RECIPE);
	const deleteRecipe = () => useMutation(DELETE_RECIPE);

	return {
		getRecipes,
		getRecipeById,
		getPopularRecipes,
		searchRecipes,
		createRecipe,
		updateRecipe,
		deleteRecipe,
	};
};

export const useRecipeInteractions = () => {
	const likeRecipe = () => useMutation(LIKE_RECIPE);
	const unlikeRecipe = () => useMutation(UNLIKE_RECIPE);
	const bookmarkRecipe = () => useMutation(BOOKMARK_RECIPE);
	const removeBookmark = () => useMutation(REMOVE_BOOKMARK);
	const addComment = () => useMutation(ADD_COMMENT);
	const rateRecipe = () => useMutation(RATE_RECIPE);

	const getUserRecipeInteractions = (userId: string, recipeId: string) => {
		return useQuery(
			GET_USER_RECIPE_INTERACTIONS,
			{ user_id: userId, recipe_id: recipeId },
			{
				errorPolicy: "all",
				skip: !userId || !recipeId,
			}
		);
	};

	const getRecipeComments = (recipeId: string, limit = 10, offset = 0) => {
		return useQuery(
			GET_RECIPE_COMMENTS,
			{ recipe_id: recipeId, limit, offset },
			{
				errorPolicy: "all",
				skip: !recipeId,
			}
		);
	};

	// Real-time subscriptions
	const subscribeToRecipeLikes = (recipeId: string) => {
		return useSubscription(SUBSCRIBE_TO_RECIPE_LIKES, { recipe_id: recipeId });
	};

	const subscribeToRecipeComments = (recipeId: string) => {
		return useSubscription(SUBSCRIBE_TO_RECIPE_COMMENTS, { recipe_id: recipeId });
	};

	return {
		likeRecipe,
		unlikeRecipe,
		bookmarkRecipe,
		removeBookmark,
		addComment,
		rateRecipe,
		getUserRecipeInteractions,
		getRecipeComments,
		subscribeToRecipeLikes,
		subscribeToRecipeComments,
	};
};

export const useCategories = () => {
	const getCategories = () => {
		return useQuery(
			GET_CATEGORIES,
			{},
			{
				errorPolicy: "all",
			}
		);
	};

	return {
		getCategories,
	};
};

export const useUserDashboard = () => {
	const getDashboardData = (userId: string) => {
		return useQuery(
			GET_USER_DASHBOARD_DATA,
			{ user_id: userId },
			{
				errorPolicy: "all",
				skip: !userId,
			}
		);
	};

	const updateUserProfile = () => useMutation(UPDATE_USER_PROFILE);

	return {
		getDashboardData,
		updateUserProfile,
	};
};

export const useRecipeAnalytics = () => {
	const getRecipeAnalytics = (recipeId: string) => {
		return useQuery(
			GET_RECIPE_ANALYTICS,
			{ recipe_id: recipeId },
			{
				errorPolicy: "all",
				skip: !recipeId,
			}
		);
	};

	return {
		getRecipeAnalytics,
	};
};

export const usePayments = () => {
	const createPurchase = () => useMutation(CREATE_PURCHASE);
	const updatePurchaseStatus = () => useMutation(UPDATE_PURCHASE_STATUS);

	return {
		createPurchase,
		updatePurchaseStatus,
	};
};