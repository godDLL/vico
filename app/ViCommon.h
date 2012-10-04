/*
 * Copyright (c) 2008-2012 Martin Hedenfalk <martin@vicoapp.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define ViSearchOptionBackwards 1

#define ViSmartPairAttributeName @"ViSmartPair"
#define ViAutoIndentAttributeName @"ViAutoIndent"
#define ViAutoNewlineAttributeName @"ViAutoNewline"
#define ViContinuationAttributeName @"ViContinuation"

#define ViDocumentLoadedNotification @"ViDocumentLoadedNotification"
#define ViDocumentAddedNotification @"ViDocumentAddedNotification"
#define ViDocumentRemovedNotification @"ViDocumentRemovedNotification"
#define ViViewClosedNotification @"ViViewClosedNotification "
#define ViFirstResponderChangedNotification @"ViFirstResponderChangedNotification"
#define ViCaretChangedNotification @"ViCaretChangedNotification"
#define ViModeChangedNotification @"ViModeChangedNotification"
#define ViDocumentEditedChangedNotification @"ViDocumentEditedChangedNotification "
#define ViURLContentsCachedNotification @"ViURLContentsCachedNotification"
#define ViTextStorageChangedLinesNotification @"ViTextStorageChangedLinesNotification"
#define ViEditPreferenceChangedNotification @"ViEditPreferenceChangedNotification"

#define ViFilterRunLoopMode @"ViFilterRunLoopMode"

#ifdef IMAX
# undef IMAX
#endif
#define IMAX(a, b)  (((NSInteger)a) > ((NSInteger)b) ? (a) : (b))

#ifdef IMIN
# undef IMIN
#endif
#define IMIN(a, b)  (((NSInteger)a) < ((NSInteger)b) ? (a) : (b))

typedef enum { ViNormalMode = 1, ViInsertMode = 2, ViVisualMode = 4, ViAnyMode = 0xFF } ViMode;

