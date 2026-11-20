package com.example.klos

import androidx.core.content.FileProvider

/**
 * FileProvider for the books handed to the mail app.
 *
 * It exists as a separate class only because the update plugin declares a
 * provider with the default `androidx.core.content.FileProvider` class as
 * well. The manifest merger joins providers that share a class name, which
 * fails on the different authorities, so klos uses its own subclass and the
 * two providers stay independent.
 */
class MailFileProvider : FileProvider()
