[
  extra: [
    theme: :acme,
    web_module: NewsflashWeb,
    sync_to_remote: true,
    long_note: String.duplicate("breaking-news-", 350) <> "TAIL_MARKER",
    edition_layouts: [
      homepage: [
        lead_story_slots: 3,
        secondary_story_slots: 6,
        photo_gallery_slots: 1,
        newsletter_promos: 2,
        podcast_highlights: 1,
        trending_topics: 5,
        local_weather_panel: true,
        market_watch_panel: true,
        corrections_banner: true
      ],
      morning_briefing: [
        hero_story_slots: 1,
        roundup_story_slots: 8,
        opinion_slots: 2,
        data_visualizations: 1,
        quote_cards: 3,
        sponsor_spots: 1,
        push_alert_recaps: true,
        audio_briefing_embed: true,
        archive_linkouts: true
      ],
      weekend_review: [
        feature_story_slots: 4,
        culture_story_slots: 4,
        sports_story_slots: 4,
        long_reads: 6,
        photo_essays: 2,
        columnists: 5,
        crossword_teaser: true,
        events_calendar: true,
        subscriber_perks: true
      ]
    ],
    desk_policies: [
      investigations: [
        fact_check_rounds: 3,
        legal_review: :required,
        correction_window: :permanent,
        photo_style: :documentary,
        audio_teaser: true,
        newsletter_slot: :front_page,
        archive_snapshot: :weekly,
        social_card_variant: :serious,
        reader_tipline: :enabled
      ],
      politics: [
        fact_check_rounds: 2,
        legal_review: :as_needed,
        correction_window: :permanent,
        photo_style: :wire,
        audio_teaser: true,
        newsletter_slot: :morning_briefing,
        archive_snapshot: :daily,
        social_card_variant: :standard,
        reader_tipline: :enabled
      ],
      culture: [
        fact_check_rounds: 1,
        legal_review: :rare,
        correction_window: :permanent,
        photo_style: :feature,
        audio_teaser: false,
        newsletter_slot: :weekend_review,
        archive_snapshot: :weekly,
        social_card_variant: :bold,
        reader_tipline: :disabled
      ]
    ],
    reader_programs: [
      subscriber_q_and_a: [
        cadence: :weekly,
        host: :city_editor,
        transcript: true,
        replay_window: {30, :days},
        spotlight_rotation: :manual,
        comments: :subscriber_only,
        signup_flow: :inline,
        theme: :newsroom_blue,
        archive_tag: :community
      ]
    ]
  ]
]
