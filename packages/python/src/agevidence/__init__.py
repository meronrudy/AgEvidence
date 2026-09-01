"""AgEvidence Python SDK.

The SDK orchestrates Rails Developer OS APIs and delegates trust operations to
configured verifier tools. It does not sign receipts, compute receipt
commitments, or verify bundles internally.
"""

from .async_client import AsyncClient
from .campaign import (
    ActivationPath,
    CampaignAccount,
    CampaignClient,
    CampaignContactRef,
    CampaignDashboard,
    CommercialHandoff,
    TechnicalQualification,
)
from .client import Client
from .errors import AgEvidenceError
from .models import (
    ArtifactDownloadMetadata,
    ArtifactOrder,
    CountryAdapterInfo,
    CountryAdapterValidation,
    CountryDetermination,
    DeveloperProject,
    EvidenceCandidate,
    IntegrationEventStatus,
    Operation,
    PricingQuote,
    ProductCatalog,
    SourceRecord,
    WebhookEndpoint,
)
from .request_models import AgEvidenceRequest
from .transport import RetryPolicy

__version__ = "0.1.0"

__all__ = [
    "AgEvidenceError",
    "AgEvidenceRequest",
    "ActivationPath",
    "ArtifactDownloadMetadata",
    "ArtifactOrder",
    "AsyncClient",
    "CampaignAccount",
    "CampaignClient",
    "CampaignContactRef",
    "CampaignDashboard",
    "Client",
    "CommercialHandoff",
    "CountryAdapterInfo",
    "CountryAdapterValidation",
    "CountryDetermination",
    "DeveloperProject",
    "EvidenceCandidate",
    "IntegrationEventStatus",
    "Operation",
    "PricingQuote",
    "ProductCatalog",
    "RetryPolicy",
    "SourceRecord",
    "TechnicalQualification",
    "WebhookEndpoint",
    "__version__",
]
