/* GStreamer dmabuf
 *
 * Copyright (c) 2012, Texas Instruments Incorporated
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef __GST_DMA_BUF_H__
#define __GST_DMA_BUF_H__

#include <gst/gst.h>


G_BEGIN_DECLS

/**
 * GstMetaDmaBuf:
 *
 * A structure that enables setting file descriptor as a metadata on a buffer.
 *
 * Since: 1.2.?
 */


typedef struct
{
  GstMeta meta;

  int fd;
} GstMetaDmaBuf;



/* attach GstMetaDmaBuf metadata to buffers */
GstMetaDmaBuf * gst_buffer_add_dma_buf_meta (GstBuffer * buf, int fd);

/* retrieve GstMetaDmaBuf metadata from buffers */
GstMetaDmaBuf * gst_buffer_get_dma_buf_meta (GstBuffer * buf);

/* retrieve file descriptor value from a GstMetaDmaBuf metadata */
int gst_dma_buf_meta_get_fd (GstMetaDmaBuf * buf);

G_END_DECLS

#endif /* __GST_DMA_BUF_H__ */
