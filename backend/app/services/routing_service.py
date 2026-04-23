import heapq
from collections import defaultdict
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.enums import AccessibilityProfile, Language
from app.models.path import Path
from app.models.user import User
from app.schemas.navigation import NavigationRouteResponse, NavigationStep


def resolve_profile(
    user: User | None,
    requested_profile: AccessibilityProfile | None,
) -> AccessibilityProfile:
    if requested_profile is not None:
        return requested_profile
    if user is not None:
        return user.accessibility_profile
    return AccessibilityProfile.none


def select_weight(path: Path, profile: AccessibilityProfile) -> float | None:
    if profile in {AccessibilityProfile.wheelchair, AccessibilityProfile.wheelchair_biometric}:
        return float(path.weight_wheelchair) if path.weight_wheelchair is not None else None

    if profile in {AccessibilityProfile.blind, AccessibilityProfile.low_vision}:
        return float(path.weight_blind) if path.weight_blind is not None else None

    return float(path.weight_default) if path.weight_default is not None else None


def select_instruction(path: Path, language: Language) -> str | None:
    if language == Language.en:
        return path.instruction_en or path.instruction_pt
    return path.instruction_pt or path.instruction_en


def build_graph(paths: list[Path], profile: AccessibilityProfile):
    graph: dict[UUID, list[tuple[UUID, float, Path]]] = defaultdict(list)

    for path in paths:
        weight = select_weight(path, profile)
        if weight is None:
            continue

        graph[path.from_location].append((path.to_location, weight, path))

        if path.is_bidirectional:
            graph[path.to_location].append((path.from_location, weight, path))

    return graph


def shortest_path(
    graph: dict[UUID, list[tuple[UUID, float, Path]]],
    start: UUID,
    goal: UUID,
):
    queue: list[tuple[float, UUID]] = [(0.0, start)]
    costs: dict[UUID, float] = {start: 0.0}
    previous: dict[UUID, tuple[UUID, Path]] = {}

    while queue:
        current_cost, current_node = heapq.heappop(queue)

        if current_node == goal:
            break

        if current_cost > costs.get(current_node, float("inf")):
            continue

        for next_node, edge_weight, path in graph.get(current_node, []):
            new_cost = current_cost + edge_weight

            if new_cost < costs.get(next_node, float("inf")):
                costs[next_node] = new_cost
                previous[next_node] = (current_node, path)
                heapq.heappush(queue, (new_cost, next_node))

    if goal not in costs:
        return None, None

    ordered_paths: list[Path] = []
    location_sequence: list[UUID] = [goal]
    cursor = goal

    while cursor != start:
        prev_node, path = previous[cursor]
        ordered_paths.append(path)
        location_sequence.append(prev_node)
        cursor = prev_node

    ordered_paths.reverse()
    location_sequence.reverse()

    return ordered_paths, location_sequence


def calculate_route(
    db: Session,
    from_location_id: UUID,
    to_location_id: UUID,
    user: User | None = None,
    requested_profile: AccessibilityProfile | None = None,
) -> NavigationRouteResponse:
    profile = resolve_profile(user, requested_profile)
    language = user.preferred_language if user else Language.pt

    paths = db.query(Path).all()
    graph = build_graph(paths, profile)

    ordered_paths, location_sequence = shortest_path(graph, from_location_id, to_location_id)
    if ordered_paths is None:
        raise ValueError("No route found for the selected accessibility profile")

    steps: list[NavigationStep] = []
    total_cost = 0.0
    total_distance = 0.0

    for path in ordered_paths:
        weight = select_weight(path, profile)
        distance = float(path.distance)
        total_cost += 0.0 if weight is None else float(weight)
        total_distance += distance

        steps.append(
            NavigationStep(
                from_location_id=path.from_location,
                to_location_id=path.to_location,
                direction=path.direction,
                distance=path.distance,
                bearing=path.bearing,
                instruction=select_instruction(path, language),
                is_accessible=path.is_accessible,
            )
        )

    return NavigationRouteResponse(
        profile_used=profile,
        total_cost=total_cost,
        total_distance=total_distance,
        steps=steps,
        location_sequence=location_sequence,
    )