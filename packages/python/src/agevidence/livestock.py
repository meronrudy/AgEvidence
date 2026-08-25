"""Livestock domain value objects for Australian evidence adapters."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class LivestockModel(BaseModel):
    model_config = ConfigDict(extra="allow")


class Animal(LivestockModel):
    animal_id: str
    species: str
    identifiers: list[str] = []


class Herd(LivestockModel):
    herd_id: str
    species: str
    production_system: str | None = None


class Intervention(LivestockModel):
    intervention_id: str
    intervention_type: str
    occurred_at: str | None = None


class FeedAdditive(Intervention):
    product_id: str | None = None
    product_batch: str | None = None
    dose_or_quantity: str | None = None
    unit: str | None = None


class Movement(LivestockModel):
    movement_id: str
    from_location: str | None = None
    to_location: str | None = None
    moved_at: str | None = None


class Weight(LivestockModel):
    subject_id: str
    value: str
    unit: str
    measured_at: str | None = None


class Milk(LivestockModel):
    subject_id: str
    volume: str
    unit: str
    measured_at: str | None = None


class MethaneObservation(LivestockModel):
    subject_id: str
    value: str
    unit: str
    method: str | None = None
    observed_at: str | None = None


class NLISIdentifier(LivestockModel):
    value: str
    issuer: str = "NLIS"
    status: str = "unverified"
