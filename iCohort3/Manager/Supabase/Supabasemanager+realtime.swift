//
//  SupabaseManager+Realtime.swift
//  iCohort3
//
//  Wraps Supabase Realtime so any VC can subscribe to task changes
//  for a specific team and get a callback the moment a row is
//  inserted, updated, or deleted in the `tasks` table.
//

import Foundation
import Supabase

extension SupabaseManager {

    // MARK: - Subscribe to task changes for a team
    //
    // Returns the RealtimeChannelV2 so the caller can unsubscribe later.
    // Call this once when the screen appears, store the channel,
    // and call channel.unsubscribe() when the screen disappears.
    //
    // `onChange` is called on the main thread every time a task row
    // for `teamId` is inserted, updated, or deleted.

    @discardableResult
    func subscribeToTaskChanges(
        teamId: String,
        onChange: @escaping () -> Void
    ) -> RealtimeChannelV2 {

        let channelName = "tasks-team-\(teamId)-\(UUID().uuidString.prefix(8))"

        let channel = client.realtimeV2.channel(channelName)

        // Listen for INSERT
        Task {
            _ = channel.onPostgresChange(
                InsertAction.self,
                schema: "public",
                table:  "tasks",
                filter: "team_id=eq.\(teamId)"
            ) { _ in
                DispatchQueue.main.async { onChange() }
            }

            // Listen for UPDATE (status changes, edits)
            _ = channel.onPostgresChange(
                UpdateAction.self,
                schema: "public",
                table:  "tasks",
                filter: "team_id=eq.\(teamId)"
            ) { _ in
                DispatchQueue.main.async { onChange() }
            }

            // Listen for DELETE
            _ = channel.onPostgresChange(
                DeleteAction.self,
                schema: "public",
                table:  "tasks",
                filter: "team_id=eq.\(teamId)"
            ) { _ in
                DispatchQueue.main.async { onChange() }
            }

            do {
                try await channel.subscribeWithError()
                print("✅ Realtime subscribed: \(channelName)")
            } catch {
                print("❌ Realtime subscribe failed: \(error)")
            }
        }

        return channel
    }

    // MARK: - Unsubscribe helper
    func unsubscribe(channel: RealtimeChannelV2?) {
        guard let channel else { return }
        Task {
            await channel.unsubscribe()
            print("🔴 Realtime unsubscribed")
        }
    }
}
