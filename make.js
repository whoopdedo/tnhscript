#!/usr/bin/env node
/*****************************************************************************
 * tnhScript 3, Copyright (C) 2017 Tom N Harris <telliamed@whoopdedo.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * The source code and GNU General Public License can be accessed
 * at <https://github.com/whoopdedo/tnhscript>
 ****************************************************************************/
'use strict'

var fs = require('fs')

var stripComments = require('./build/commentRemover.js').stripComments

var args = process.argv.slice (2)

fs.readFile ('src/prologue.nut', 'utf8', (err, data) => {
  if (err)
    console.error (err)
  else
  {
    // normalize eols here
    if (~data.indexOf ('\r'))
      data = data.replace (/\r\n?/g, '\n')
    process.stdout.write (data .replace (/\n/g, '\r\n'))

    stripFile(args.shift())
  }
})

function stripFile (file) {
  if (file)
    fs.readFile (file, 'utf8', (err, data) => {
      if (err)
        console.error (err)
      else
      {
        // normalize eols here
        if (~data.indexOf ('\r'))
          data = data.replace (/\r\n?/g, '\n')
        process.stdout.write (stripComments (data) .replace (/\n/g, '\r\n') )

        stripFile(args.shift())
      }
    })
}
