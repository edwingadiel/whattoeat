import { scoreCandidates, type CandidateItem, type RecommendationRequest } from "../shared/scoring.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const body = (await request.json()) as RecommendationRequest & {
    candidateItems?: CandidateItem[];
    favoriteIds?: string[];
    likedIds?: string[];
  };

  const favoriteIds = body.favoriteIds ?? [];
  const likedIds = body.likedIds ?? [];
  const candidateItems = body.candidateItems ?? [];

  let ranked = scoreCandidates(candidateItems, body, favoriteIds, likedIds, false);
  let expanded = false;

  if (ranked.length < 3) {
    ranked = scoreCandidates(candidateItems, body, favoriteIds, likedIds, true);
    expanded = true;
  }

  const topRecommendations = ranked.slice(0, 3);
  const alternateRecommendations = ranked.slice(3, 6);

  return Response.json({
    top_recommendations: topRecommendations,
    alternate_recommendations: alternateRecommendations,
    used_expanded_tolerance: expanded,
    guidance:
      topRecommendations.length === 0
        ? "No strong matches found."
        : expanded
        ? "No exact hits matched your target, so these are the closest fits."
        : null
  });
});
