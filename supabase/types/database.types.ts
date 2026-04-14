export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      buyer_reviews: {
        Row: {
          buyer_id: string
          buyer_reply: string | null
          buyer_reply_at: string | null
          comment: string | null
          created_at: string
          id: string
          order_id: string
          rating: number
          seller_id: string
        }
        Insert: {
          buyer_id: string
          buyer_reply?: string | null
          buyer_reply_at?: string | null
          comment?: string | null
          created_at?: string
          id?: string
          order_id: string
          rating: number
          seller_id: string
        }
        Update: {
          buyer_id?: string
          buyer_reply?: string | null
          buyer_reply_at?: string | null
          comment?: string | null
          created_at?: string
          id?: string
          order_id?: string
          rating?: number
          seller_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "buyer_reviews_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          icon: string | null
          id: string
          name: string
          order: number | null
          parent_id: string | null
          section: string | null
          slug: string | null
        }
        Insert: {
          icon?: string | null
          id?: string
          name: string
          order?: number | null
          parent_id?: string | null
          section?: string | null
          slug?: string | null
        }
        Update: {
          icon?: string | null
          id?: string
          name?: string
          order?: number | null
          parent_id?: string | null
          section?: string | null
          slug?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_typing: {
        Row: {
          conversation_id: string
          is_typing: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          is_typing?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          is_typing?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_typing_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_user_prefs: {
        Row: {
          conversation_id: string
          hidden: boolean
          is_favorite: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          hidden?: boolean
          is_favorite?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          hidden?: boolean
          is_favorite?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_user_prefs_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          buyer_id: string
          created_at: string | null
          id: string
          order_id: string | null
          seller_id: string
          updated_at: string | null
        }
        Insert: {
          buyer_id: string
          created_at?: string | null
          id?: string
          order_id?: string | null
          seller_id: string
          updated_at?: string | null
        }
        Update: {
          buyer_id?: string
          created_at?: string | null
          id?: string
          order_id?: string | null
          seller_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "conversations_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      edge_config: {
        Row: {
          key: string
          value: string
        }
        Insert: {
          key: string
          value: string
        }
        Update: {
          key?: string
          value?: string
        }
        Relationships: []
      }
      favorite_sellers: {
        Row: {
          created_at: string | null
          id: string
          seller_id: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          seller_id: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          seller_id?: string
          user_id?: string
        }
        Relationships: []
      }
      favorites: {
        Row: {
          created_at: string
          id: string
          product_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          product_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          product_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "product_listing_autoflags"
            referencedColumns: ["product_id"]
          },
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products_with_ratings"
            referencedColumns: ["id"]
          },
        ]
      }
      message_reactions: {
        Row: {
          conversation_id: string
          created_at: string
          id: string
          message_id: string
          reaction: string
          updated_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          created_at?: string
          id?: string
          message_id: string
          reaction: string
          updated_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          created_at?: string
          id?: string
          message_id?: string
          reaction?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_reactions_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_reactions_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "messages"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          body: string
          conversation_id: string
          created_at: string | null
          id: string
          read_at: string | null
          sender_id: string
        }
        Insert: {
          body: string
          conversation_id: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id: string
        }
        Update: {
          body?: string
          conversation_id?: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string | null
          created_at: string | null
          id: string
          order_id: string | null
          read_at: string | null
          ticket_id: string | null
          title: string
          type: string
          user_id: string
        }
        Insert: {
          body?: string | null
          created_at?: string | null
          id?: string
          order_id?: string | null
          read_at?: string | null
          ticket_id?: string | null
          title: string
          type: string
          user_id: string
        }
        Update: {
          body?: string | null
          created_at?: string | null
          id?: string
          order_id?: string | null
          read_at?: string | null
          ticket_id?: string | null
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string
          product_name: string
          quantity_kg: number
          total_price: number | null
          unit_price: number | null
          unit_type: string
        }
        Insert: {
          id?: string
          order_id: string
          product_id: string
          product_name: string
          quantity_kg: number
          total_price?: number | null
          unit_price?: number | null
          unit_type?: string
        }
        Update: {
          id?: string
          order_id?: string
          product_id?: string
          product_name?: string
          quantity_kg?: number
          total_price?: number | null
          unit_price?: number | null
          unit_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "product_listing_autoflags"
            referencedColumns: ["product_id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products_with_ratings"
            referencedColumns: ["id"]
          },
        ]
      }
      order_status_audit_logs: {
        Row: {
          changed_at: string
          changed_by_role: string
          changed_by_user_id: string | null
          id: string
          new_status: string
          old_status: string
          order_id: string
        }
        Insert: {
          changed_at?: string
          changed_by_role: string
          changed_by_user_id?: string | null
          id?: string
          new_status: string
          old_status: string
          order_id: string
        }
        Update: {
          changed_at?: string
          changed_by_role?: string
          changed_by_user_id?: string | null
          id?: string
          new_status?: string
          old_status?: string
          order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_status_audit_logs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          archived_at: string | null
          buyer_address: string | null
          buyer_city: string | null
          buyer_id: string
          buyer_phone: string
          cancellation_reason: string | null
          created_at: string | null
          delivery_address: string | null
          delivery_city: string | null
          delivery_fee_rsd: number | null
          delivery_method: string | null
          delivery_point_id: string | null
          delivery_point_label: string | null
          delivery_time_from: string | null
          delivery_time_to: string | null
          delivery_weekday: number | null
          expires_at: string
          id: string
          note: string | null
          prefer_call: boolean | null
          product_id: string | null
          product_name: string | null
          quantity_kg: number | null
          seller_id: string
          status: string | null
          total_amount: number | null
          unit_type: string
        }
        Insert: {
          archived_at?: string | null
          buyer_address?: string | null
          buyer_city?: string | null
          buyer_id: string
          buyer_phone: string
          cancellation_reason?: string | null
          created_at?: string | null
          delivery_address?: string | null
          delivery_city?: string | null
          delivery_fee_rsd?: number | null
          delivery_method?: string | null
          delivery_point_id?: string | null
          delivery_point_label?: string | null
          delivery_time_from?: string | null
          delivery_time_to?: string | null
          delivery_weekday?: number | null
          expires_at?: string
          id?: string
          note?: string | null
          prefer_call?: boolean | null
          product_id?: string | null
          product_name?: string | null
          quantity_kg?: number | null
          seller_id: string
          status?: string | null
          total_amount?: number | null
          unit_type?: string
        }
        Update: {
          archived_at?: string | null
          buyer_address?: string | null
          buyer_city?: string | null
          buyer_id?: string
          buyer_phone?: string
          cancellation_reason?: string | null
          created_at?: string | null
          delivery_address?: string | null
          delivery_city?: string | null
          delivery_fee_rsd?: number | null
          delivery_method?: string | null
          delivery_point_id?: string | null
          delivery_point_label?: string | null
          delivery_time_from?: string | null
          delivery_time_to?: string | null
          delivery_weekday?: number | null
          expires_at?: string
          id?: string
          note?: string | null
          prefer_call?: boolean | null
          product_id?: string | null
          product_name?: string | null
          quantity_kg?: number | null
          seller_id?: string
          status?: string | null
          total_amount?: number | null
          unit_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_delivery_point_id_fkey"
            columns: ["delivery_point_id"]
            isOneToOne: false
            referencedRelation: "seller_delivery_points"
            referencedColumns: ["id"]
          },
        ]
      }
      product_delivery_points: {
        Row: {
          created_at: string
          delivery_point_id: string
          product_id: string
        }
        Insert: {
          created_at?: string
          delivery_point_id: string
          product_id: string
        }
        Update: {
          created_at?: string
          delivery_point_id?: string
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_delivery_points_delivery_point_id_fkey"
            columns: ["delivery_point_id"]
            isOneToOne: false
            referencedRelation: "seller_delivery_points"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_delivery_points_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "product_listing_autoflags"
            referencedColumns: ["product_id"]
          },
          {
            foreignKeyName: "product_delivery_points_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_delivery_points_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products_with_ratings"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          available_kg: number | null
          available_now: boolean | null
          category: string
          created_at: string | null
          delivery_mode: string
          description: string | null
          id: string
          image_urls: string[] | null
          is_domestic: boolean | null
          location: string
          min_order_kg: number | null
          name: string
          order_step: number
          origin: string
          pickup_options: string[] | null
          price_per_kg: number
          seller_id: string
          shelf_life_days: number
          unit_type: string
        }
        Insert: {
          available_kg?: number | null
          available_now?: boolean | null
          category: string
          created_at?: string | null
          delivery_mode?: string
          description?: string | null
          id?: string
          image_urls?: string[] | null
          is_domestic?: boolean | null
          location: string
          min_order_kg?: number | null
          name: string
          order_step?: number
          origin?: string
          pickup_options?: string[] | null
          price_per_kg: number
          seller_id: string
          shelf_life_days?: number
          unit_type?: string
        }
        Update: {
          available_kg?: number | null
          available_now?: boolean | null
          category?: string
          created_at?: string | null
          delivery_mode?: string
          description?: string | null
          id?: string
          image_urls?: string[] | null
          is_domestic?: boolean | null
          location?: string
          min_order_kg?: number | null
          name?: string
          order_step?: number
          origin?: string
          pickup_options?: string[] | null
          price_per_kg?: number
          seller_id?: string
          shelf_life_days?: number
          unit_type?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          city: string | null
          created_at: string | null
          display_name: string | null
          email: string | null
          farm_gallery_urls: string[] | null
          farm_name: string | null
          id: string
          is_admin: boolean
          is_guest: boolean | null
          is_verified: boolean | null
          lat: number | null
          lng: number | null
          location: string | null
          phone: string | null
          phone_public: boolean
          profile_image_url: string | null
          role: string | null
          seller_quick_replies: string[] | null
          seller_story: string | null
          seller_tags: string[] | null
          updated_at: string | null
        }
        Insert: {
          city?: string | null
          created_at?: string | null
          display_name?: string | null
          email?: string | null
          farm_gallery_urls?: string[] | null
          farm_name?: string | null
          id: string
          is_admin?: boolean
          is_guest?: boolean | null
          is_verified?: boolean | null
          lat?: number | null
          lng?: number | null
          location?: string | null
          phone?: string | null
          phone_public?: boolean
          profile_image_url?: string | null
          role?: string | null
          seller_quick_replies?: string[] | null
          seller_story?: string | null
          seller_tags?: string[] | null
          updated_at?: string | null
        }
        Update: {
          city?: string | null
          created_at?: string | null
          display_name?: string | null
          email?: string | null
          farm_gallery_urls?: string[] | null
          farm_name?: string | null
          id?: string
          is_admin?: boolean
          is_guest?: boolean | null
          is_verified?: boolean | null
          lat?: number | null
          lng?: number | null
          location?: string | null
          phone?: string | null
          phone_public?: boolean
          profile_image_url?: string | null
          role?: string | null
          seller_quick_replies?: string[] | null
          seller_story?: string | null
          seller_tags?: string[] | null
          updated_at?: string | null
        }
        Relationships: []
      }
      push_delivery_logs: {
        Row: {
          created_at: string
          errors: Json
          failed_count: number
          id: number
          payload: Json
          request_id: string
          sent_count: number
          source: string
          status: string
          title: string | null
          token_count: number
          type: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string
          errors?: Json
          failed_count?: number
          id?: never
          payload?: Json
          request_id: string
          sent_count?: number
          source?: string
          status: string
          title?: string | null
          token_count?: number
          type?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string
          errors?: Json
          failed_count?: number
          id?: never
          payload?: Json
          request_id?: string
          sent_count?: number
          source?: string
          status?: string
          title?: string | null
          token_count?: number
          type?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      reviews: {
        Row: {
          buyer_id: string
          comment: string | null
          created_at: string | null
          id: string
          order_id: string | null
          product_id: string | null
          rating: number
          seller_id: string
          seller_reply: string | null
          seller_reply_at: string | null
        }
        Insert: {
          buyer_id: string
          comment?: string | null
          created_at?: string | null
          id?: string
          order_id?: string | null
          product_id?: string | null
          rating: number
          seller_id: string
          seller_reply?: string | null
          seller_reply_at?: string | null
        }
        Update: {
          buyer_id?: string
          comment?: string | null
          created_at?: string | null
          id?: string
          order_id?: string | null
          product_id?: string | null
          rating?: number
          seller_id?: string
          seller_reply?: string | null
          seller_reply_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reviews_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "product_listing_autoflags"
            referencedColumns: ["product_id"]
          },
          {
            foreignKeyName: "reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products_with_ratings"
            referencedColumns: ["id"]
          },
        ]
      }
      seller_delivery_points: {
        Row: {
          address: string
          city: string
          created_at: string
          id: string
          is_active: boolean
          label: string
          lat: number | null
          lng: number | null
          notes: string | null
          seller_id: string
          updated_at: string
        }
        Insert: {
          address: string
          city: string
          created_at?: string
          id?: string
          is_active?: boolean
          label: string
          lat?: number | null
          lng?: number | null
          notes?: string | null
          seller_id: string
          updated_at?: string
        }
        Update: {
          address?: string
          city?: string
          created_at?: string
          id?: string
          is_active?: boolean
          label?: string
          lat?: number | null
          lng?: number | null
          notes?: string | null
          seller_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      seller_delivery_slots: {
        Row: {
          created_at: string
          delivery_fee_rsd: number | null
          delivery_point_id: string
          id: string
          is_active: boolean
          max_orders: number | null
          min_order_amount_rsd: number | null
          time_from: string
          time_to: string
          updated_at: string
          weekday: number
        }
        Insert: {
          created_at?: string
          delivery_fee_rsd?: number | null
          delivery_point_id: string
          id?: string
          is_active?: boolean
          max_orders?: number | null
          min_order_amount_rsd?: number | null
          time_from: string
          time_to: string
          updated_at?: string
          weekday: number
        }
        Update: {
          created_at?: string
          delivery_fee_rsd?: number | null
          delivery_point_id?: string
          id?: string
          is_active?: boolean
          max_orders?: number | null
          min_order_amount_rsd?: number | null
          time_from?: string
          time_to?: string
          updated_at?: string
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "seller_delivery_slots_delivery_point_id_fkey"
            columns: ["delivery_point_id"]
            isOneToOne: false
            referencedRelation: "seller_delivery_points"
            referencedColumns: ["id"]
          },
        ]
      }
      support_ticket_messages: {
        Row: {
          body: string
          created_at: string
          id: string
          sender_id: string
          sender_role: string
          ticket_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          sender_id: string
          sender_role: string
          ticket_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          sender_id?: string
          sender_role?: string
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_ticket_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          admin_note: string | null
          body: string
          category: string
          created_at: string
          id: string
          status: string
          subject: string
          ticket_number: string
          updated_at: string
          user_email: string | null
          user_id: string | null
          user_name: string | null
        }
        Insert: {
          admin_note?: string | null
          body: string
          category?: string
          created_at?: string
          id?: string
          status?: string
          subject: string
          ticket_number?: string
          updated_at?: string
          user_email?: string | null
          user_id?: string | null
          user_name?: string | null
        }
        Update: {
          admin_note?: string | null
          body?: string
          category?: string
          created_at?: string
          id?: string
          status?: string
          subject?: string
          ticket_number?: string
          updated_at?: string
          user_email?: string | null
          user_id?: string | null
          user_name?: string | null
        }
        Relationships: []
      }
      user_push_tokens: {
        Row: {
          created_at: string | null
          id: string
          installation_id: string
          platform: string | null
          token: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          installation_id: string
          platform?: string | null
          token: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          installation_id?: string
          platform?: string | null
          token?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      ordering_audit_summary: {
        Row: {
          clean_products: number | null
          generated_at: string | null
          problem_products: number | null
          problem_rate_percent: number | null
          total_products: number | null
        }
        Relationships: []
      }
      product_listing_autoflags: {
        Row: {
          category: string | null
          cross_category_duplicates: number | null
          has_issues: boolean | null
          issues: string[] | null
          missing_image: boolean | null
          missing_origin: boolean | null
          missing_pickup: boolean | null
          missing_shelf_life: boolean | null
          name: string | null
          normalized_category: string | null
          normalized_name: string | null
          product_id: string | null
          same_category_duplicates: number | null
          seller_id: string | null
        }
        Relationships: []
      }
      products_with_ratings: {
        Row: {
          available_kg: number | null
          available_now: boolean | null
          avg_rating: number | null
          category: string | null
          created_at: string | null
          delivery_mode: string | null
          description: string | null
          id: string | null
          image_urls: string[] | null
          is_domestic: boolean | null
          location: string | null
          min_order_kg: number | null
          name: string | null
          order_count: number | null
          order_step: number | null
          pickup_options: string[] | null
          price_per_kg: number | null
          review_count: number | null
          seller_id: string | null
          unit_type: string | null
        }
        Relationships: []
      }
      push_health_dashboard: {
        Row: {
          anon_key_present: boolean | null
          checked_at: string | null
          deliveries_24h: number | null
          delivery_backlog_minutes: number | null
          edge_config_ok: boolean | null
          failed_deliveries_24h: number | null
          functions_base_url: string | null
          health: string | null
          last_delivery_at: string | null
          last_notification_at: string | null
          notifications_24h: number | null
          success_rate_pct: number | null
          successful_deliveries_24h: number | null
          tokens_created_24h: number | null
          total_tokens: number | null
          users_with_tokens: number | null
        }
        Relationships: []
      }
      push_health_user_issues: {
        Row: {
          checked_at: string | null
          health: string | null
          latest_delivery_at: string | null
          latest_delivery_error_count: number | null
          latest_delivery_status: string | null
          latest_notification_at: string | null
          latest_token_at: string | null
          notifications_7d: number | null
          token_count: number | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      add_buyer_reply: {
        Args: { p_reply: string; p_review_id: string }
        Returns: undefined
      }
      add_seller_reply: {
        Args: { p_reply: string; p_review_id: string }
        Returns: undefined
      }
      archive_and_expire_orders: { Args: never; Returns: undefined }
      audit_product_ordering: {
        Args: { p_limit?: number }
        Returns: {
          category: string
          issues: string[]
          min_quantity: number
          name: string
          order_step: number
          product_id: string
          sample_options: string
          suggested_min: number
          suggested_step: number
          suggested_unit: string
          unit_type: string
        }[]
      }
      build_order_notification_body: {
        Args: {
          p_fallback_product_name?: string
          p_fallback_quantity?: number
          p_fallback_unit_type?: string
          p_order_id: string
        }
        Returns: string
      }
      buyer_confirm_order_received: {
        Args: { p_order_id: string }
        Returns: boolean
      }
      cleanup_push_tokens: {
        Args: { p_keep_per_user?: number; p_max_age?: string }
        Returns: number
      }
      create_order_with_items: {
        Args: {
          p_buyer_address?: string
          p_buyer_city?: string
          p_buyer_id: string
          p_buyer_phone: string
          p_delivery_fee_rsd?: number
          p_delivery_method?: string
          p_delivery_point_id?: string
          p_delivery_slot_id?: string
          p_items: Json
          p_note?: string
          p_seller_id: string
        }
        Returns: string
      }
      get_conversation_info_with_profile: {
        Args: { p_conversation_id: string }
        Returns: {
          buyer_id: string
          buyer_name: string
          id: string
          order_id: string
          seller_id: string
          seller_name: string
        }[]
      }
      get_conversations_for_user: { Args: { p_user_id: string }; Returns: Json }
      get_favorite_sellers_with_profiles: {
        Args: { p_user_id: string }
        Returns: {
          city: string | null
          created_at: string | null
          display_name: string | null
          email: string | null
          farm_gallery_urls: string[] | null
          farm_name: string | null
          id: string
          is_admin: boolean
          is_guest: boolean | null
          is_verified: boolean | null
          lat: number | null
          lng: number | null
          location: string | null
          phone: string | null
          phone_public: boolean
          profile_image_url: string | null
          role: string | null
          seller_quick_replies: string[] | null
          seller_story: string | null
          seller_tags: string[] | null
          updated_at: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_home_products: {
        Args: { p_category?: string; p_limit?: number; p_region?: string }
        Returns: {
          available_kg: number
          available_now: boolean
          category: string
          created_at: string
          delivery_mode: string
          description: string
          id: string
          image_urls: string[]
          is_domestic: boolean
          location: string
          min_order_kg: number
          name: string
          order_count: number
          order_step: number
          pickup_options: string[]
          price_per_kg: number
          seller_id: string
          unit_type: string
        }[]
      }
      get_my_product_listing_autoflag_summary: {
        Args: never
        Returns: {
          clean_products: number
          problem_products: number
          problem_rate_percent: number
          total_products: number
        }[]
      }
      get_my_product_listing_autoflags: {
        Args: never
        Returns: {
          category: string
          cross_category_duplicates: number
          has_issues: boolean
          issues: string[]
          missing_image: boolean
          missing_origin: boolean
          missing_pickup: boolean
          missing_shelf_life: boolean
          name: string
          normalized_category: string
          normalized_name: string
          product_id: string
          same_category_duplicates: number
          seller_id: string
        }[]
      }
      get_product_ratings: {
        Args: never
        Returns: {
          avg_rating: number
          product_id: string
          review_count: number
        }[]
      }
      get_product_sales_counts: {
        Args: never
        Returns: {
          order_count: number
          product_id: string
        }[]
      }
      get_products_from_favorite_sellers: {
        Args: { p_user_id: string }
        Returns: {
          available_kg: number | null
          available_now: boolean | null
          category: string
          created_at: string | null
          delivery_mode: string
          description: string | null
          id: string
          image_urls: string[] | null
          is_domestic: boolean | null
          location: string
          min_order_kg: number | null
          name: string
          order_step: number
          origin: string
          pickup_options: string[] | null
          price_per_kg: number
          seller_id: string
          shelf_life_days: number
          unit_type: string
        }[]
        SetofOptions: {
          from: "*"
          to: "products"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_reviewable_order: {
        Args: { p_buyer_id: string; p_seller_id: string }
        Returns: Json
      }
      get_seller_inbox: { Args: { p_seller_id: string }; Returns: Json }
      get_seller_loyalty_stats: { Args: { p_seller_id: string }; Returns: Json }
      get_seller_response_time_stats: {
        Args: { p_seller_id: string }
        Returns: {
          avg_response_minutes: number
          last_response_minutes: number
          median_response_minutes: number
          sample_count: number
        }[]
      }
      get_seller_stats: { Args: { p_seller_id: string }; Returns: Json }
      get_seller_stats_dashboard: {
        Args: { p_seller_id: string }
        Returns: Json
      }
      handle_order_retention: { Args: never; Returns: undefined }
      normalize_listing_key: { Args: { input_value: string }; Returns: string }
      push_health_summary: {
        Args: never
        Returns: {
          anon_key_present: boolean
          checked_at: string
          deliveries_24h: number
          delivery_backlog_minutes: number
          edge_config_ok: boolean
          failed_deliveries_24h: number
          functions_base_url: string
          health: string
          last_delivery_at: string
          last_notification_at: string
          notifications_24h: number
          success_rate_pct: number
          successful_deliveries_24h: number
          tokens_created_24h: number
          total_tokens: number
          users_with_tokens: number
        }[]
      }
      push_user_health: {
        Args: { target_user_id: string }
        Returns: {
          checked_at: string
          health: string
          latest_delivery_at: string
          latest_delivery_error_count: number
          latest_delivery_status: string
          latest_notification_at: string
          latest_token_at: string
          notifications_7d: number
          token_count: number
          user_id: string
        }[]
      }
      set_conversation_user_prefs: {
        Args: {
          p_conversation_id: string
          p_hidden?: boolean
          p_is_favorite?: boolean
        }
        Returns: undefined
      }
      set_product_delivery_scope: {
        Args: {
          p_delivery_mode: string
          p_delivery_point_ids?: string[]
          p_product_id: string
        }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const

