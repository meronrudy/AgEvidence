module PortfolioProducts
  class Navigation
    Item = Data.define(:target, :label, :capability, :badge_source)
    Section = Data.define(:label, :items)

    attr_reader :sections

    def initialize(sections = [])
      @sections = Array(sections).map do |section|
        Section.new(
          label: section["label"],
          items: Array(section["items"]).map do |item|
            Item.new(
              target: item.fetch("target"),
              label: item.fetch("label"),
              capability: item["capability"],
              badge_source: item["badge_source"]
            )
          end
        )
      end
    end

    def visible_for(pack)
      sections.map do |section|
        visible_items = section.items.select { |item| item.capability.blank? || pack.enabled?(item.capability) }
        Section.new(label: section.label, items: visible_items)
      end.reject { |section| section.items.empty? }
    end

    def targets
      sections.flat_map { |section| section.items.map(&:target) }
    end
  end
end
