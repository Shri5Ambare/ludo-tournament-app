-- Ludo Tournament App - Supabase Schema
-- Run this in your Supabase SQL Editor

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_emoji TEXT DEFAULT '👨‍💼',
  level INTEGER DEFAULT 1,
  wins INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Game Rooms Table
CREATE TABLE IF NOT EXISTS public.rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  host_id UUID REFERENCES auth.users NOT NULL,
  host_name TEXT NOT NULL,
  game_mode TEXT DEFAULT 'classic' NOT NULL,
  max_players INTEGER DEFAULT 4 NOT NULL,
  turn_timer INTEGER DEFAULT 30 NOT NULL,
  status TEXT DEFAULT 'waiting' NOT NULL, -- 'waiting', 'starting', 'inProgress', 'finished'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on rooms
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Rooms are viewable by everyone" 
ON public.rooms FOR SELECT USING (true);

CREATE POLICY "Only hosts can update room settings" 
ON public.rooms FOR UPDATE USING (auth.uid() = host_id);

-- 3. Room Participants
CREATE TABLE IF NOT EXISTS public.participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  avatar_emoji TEXT NOT NULL,
  is_ready BOOLEAN DEFAULT false NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(room_id, user_id)
);

-- Enable RLS on participants
ALTER TABLE public.participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants are viewable by everyone" 
ON public.participants FOR SELECT USING (true);

CREATE POLICY "Users can join rooms" 
ON public.participants FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own readiness" 
ON public.participants FOR UPDATE USING (auth.uid() = user_id);

-- 4. Game Events (Realtime Action Stream)
CREATE TABLE IF NOT EXISTS public.game_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE NOT NULL,
  player_id UUID REFERENCES auth.users NOT NULL,
  event_type TEXT NOT NULL, -- 'roll_dice', 'move_token', 'chat'
  payload JSONB DEFAULT '{}' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on game_events
ALTER TABLE public.game_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Game events are viewable by everyone in the room" 
ON public.game_events FOR SELECT USING (true);

CREATE POLICY "Participants can broadcast events" 
ON public.game_events FOR INSERT WITH CHECK (
  auth.uid() = player_id
);

-- 5. Social: Friendships
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  friend_id UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, friend_id)
);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their own friends" 
ON public.friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- 6. Social: Friend Requests
CREATE TABLE IF NOT EXISTS public.friend_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  from_id UUID REFERENCES auth.users NOT NULL,
  to_id UUID REFERENCES auth.users NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL, -- 'pending', 'accepted', 'rejected'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(from_id, to_id)
);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see requests involving them" 
ON public.friend_requests FOR SELECT USING (auth.uid() = from_id OR auth.uid() = to_id);

CREATE POLICY "Users can send requests" 
ON public.friend_requests FOR INSERT WITH CHECK (auth.uid() = from_id);

CREATE POLICY "Users can update requests to them" 
ON public.friend_requests FOR UPDATE USING (auth.uid() = to_id);

-- 7. Social: Game Invites
CREATE TABLE IF NOT EXISTS public.game_invites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  from_id UUID REFERENCES auth.users NOT NULL,
  to_id UUID REFERENCES auth.users NOT NULL,
  room_code TEXT NOT NULL,
  game_mode TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.game_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see invites to them" 
ON public.game_invites FOR SELECT USING (auth.uid() = to_id);

CREATE POLICY "Users can send invites" 
ON public.game_invites FOR INSERT WITH CHECK (auth.uid() = from_id);

-- 8. Tournaments
CREATE TABLE IF NOT EXISTS public.tournaments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  host_id UUID REFERENCES auth.users NOT NULL,
  type TEXT DEFAULT 'online' NOT NULL, -- 'offline', 'hotspot', 'online'
  status TEXT DEFAULT 'setup' NOT NULL, -- 'setup', 'inProgress', 'completed'
  game_mode TEXT DEFAULT 'classic' NOT NULL,
  turn_timer_seconds INTEGER DEFAULT 30 NOT NULL,
  custom_rules JSONB DEFAULT '{}' NOT NULL,
  champion_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tournaments are viewable by everyone" 
ON public.tournaments FOR SELECT USING (true);

CREATE POLICY "Only hosts can manage their tournaments" 
ON public.tournaments FOR ALL USING (auth.uid() = host_id);

-- 9. Tournament Participants
CREATE TABLE IF NOT EXISTS public.tournament_participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID, -- NULL for bots
  name TEXT NOT NULL,
  avatar_emoji TEXT NOT NULL,
  is_bot BOOLEAN DEFAULT false NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.tournament_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants are viewable by everyone" 
ON public.tournament_participants FOR SELECT USING (true);

-- 10. Tournament Groups
CREATE TABLE IF NOT EXISTS public.tournament_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
  group_index INTEGER NOT NULL,
  winner_name TEXT,
  is_complete BOOLEAN DEFAULT false NOT NULL,
  UNIQUE(tournament_id, group_index)
);

ALTER TABLE public.tournament_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Groups are viewable by everyone" 
ON public.tournament_groups FOR SELECT USING (true);

-- 11. Enable Realtime
-- In Supabase UI: Database -> Replication -> Enable for 'rooms', 'participants', 'game_events', 'tournaments', 'tournament_groups'
-- ALTER PUBLICATION supabase_realtime ADD TABLE rooms, participants, game_events, tournaments, tournament_groups;
