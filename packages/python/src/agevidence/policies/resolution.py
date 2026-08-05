"""Policy stack resolution helpers."""

from __future__ import annotations

from agevidence.policies.models import PolicyResolution, PolicyResolutionResult, PolicyStackEntry


def resolve_policy_stack(entries: list[PolicyStackEntry]) -> PolicyResolution:
    """Resolve profile entries without silently hiding conflicts."""

    requirements: list[str] = []
    results: list[PolicyResolutionResult] = []
    for entry in entries:
        for requirement in entry.requirements:
            if requirement not in requirements:
                requirements.append(requirement)
                code = "compatible" if entry.layer in {"global", "country"} else "requirement_added"
                if entry.layer == "institution":
                    code = "institution_specific_requirement"
                results.append(
                    PolicyResolutionResult(
                        code=code,
                        requirement=requirement,
                        source_profile=entry.profile_id,
                        message=f"{entry.profile_id} contributes {requirement}",
                    )
                )
    return PolicyResolution(stack=entries, requirements=requirements, results=results)

