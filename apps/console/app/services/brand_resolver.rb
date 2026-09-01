class BrandResolver
  ResolvedBrand = Data.define(
    :product_name,
    :company_name,
    :accent_token,
    :logo,
    :favicon,
    :footer,
    :support_email,
    :support_label,
    :brand_domain,
    :attribution_label,
    :pack
  )

  def self.resolve(organization: nil, artifact: nil)
    org = organization || artifact&.organization || Current.organization
    pack = org&.product_pack || Current.product_pack || PortfolioProducts::NullPack.new
    brand = pack.brand

    ResolvedBrand.new(
      product_name: org&.brand_name.presence || brand.product_name,
      company_name: org&.legal_entity_name.presence || brand.company_name,
      accent_token: brand.accent_token,
      logo: brand.logo,
      favicon: brand.favicon,
      footer: brand.footer,
      support_email: org&.support_email.presence || brand.support["email"],
      support_label: brand.support["label"],
      brand_domain: org&.brand_domain.presence,
      attribution_label: brand.attribution_label,
      pack: pack
    )
  end
end
